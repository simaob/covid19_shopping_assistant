# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default("")
#  encrypted_password     :string           default("")
#  name                   :string
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  app_uuid               :string
#  last_post              :datetime
#  role                   :integer          default("0")
#  store_owner_code       :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  phone                  :string
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  badges_tracker         :jsonb
#  badges_won             :string           default("")
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :registerable,
         :confirmable, :trackable

  with_options if: :admin? do
    validates :email, presence: true
    validates :password, presence: true, if: :password_required?
    validates :password, confirmation: true, if: :password_required?
    validates :password, length: {within: 8..128, allow_blank: true}
  end
  validates :email, uniqueness: true, unless: proc { |u| u.email.blank? }
  validates :phone, uniqueness: true, unless: proc { |u| u.phone.blank? }

  before_save :add_badges, if: :will_save_change_to_badges_tracker?

  has_many :user_stores, inverse_of: :manager
  has_many :stores, through: :user_stores
  has_many :created_stores, class_name: 'Store', foreign_key: :created_by_id, inverse_of: :created_by
  has_many :status_crowdsource_users
  has_many :favorites
  has_many :stores, through: :favorites, source: :store
  has_one :api_key
  has_many :user_badges
  has_many :badges, through: :user_badges
  has_one :ranking
  has_many :ranking_histories

  has_secure_token :store_owner_code

  enum role: {user: 0, store_owner: 1, general_manager: 2, admin: 3, contributor: 4,
              beach_admin: 5, beach_manager: 6}

  def self.search(search)
    return all unless search

    where('users.name ilike ? OR email ilike ? OR app_uuid ilike ?',
          "%#{search}%", "%#{search}%",
          "%#{search}%")
  end

  def display_name
    name.presence || email.presence || "ID: #{id}"
  end
  alias_method :text, :display_name

  def regenerate_api_key
    return unless persisted?

    ApiKey.where(user_id: id).update(active: false)
    ApiKey.create(user: self, active: true)
  end

  def any_admin?
    admin? || beach_admin?
  end

  def reporter_rank
    ranking&.position || 0
  end

  def reporter_score
    ranking&.score || 0
  end

  def reporter_reports
    ranking&.reports || 0
  end

  def reporter_places
    ranking&.places || 0
  end

  def increase_login_counter
    return unless badges_tracker['sign_in_date'] != Date.current

    create_badges_tracker if badges_tracker.blank?
    badges_tracker['sign_in_date'] = Date.current
    badges_tracker['daily_login_count'] += 1
    save
  end

  def increase_conquests_counter(position)
    create_badges_tracker if badges_tracker.blank?
    return unless last_conquest_updated_more_than_a_month_ago?

    badges_tracker['conquests_updated_at'] = Date.current
    case position
    when 1
      badges_tracker['top_1'] += 1
    when 2..10
      badges_tracker['top_10'] += 1
    when 11..50
      badges_tracker['top_50'] += 1
    when 51..100
      badges_tracker['top_100'] += 1
    end
    save
  end

  def increase_badges_counter(report)
    fields = [{'type' => 'total_reports', 'id' => report[:id]}]
    fields << {'type' => report[:type], 'id' => report[:id]} if report[:id] && report[:type]
    create_badges_tracker if badges_tracker.blank?
    fields.each do |field|
      store_ = field['type'].gsub '_reports', '_'
      badges_tracker[field['type']] += 1
      badges_tracker["#{store_}list"] << field['id']
      badges_tracker["#{store_}list"] = badges_tracker["#{store_}list"].uniq
      badges_tracker["#{store_}unique"] = badges_tracker["#{store_}list"].count
    end
    save
  end

  def last_conquest_updated_more_than_a_month_ago?
    last_update = badges_tracker.dig('conquests_updated_at')
    return true if last_update.blank?

    ((Date.current.year * 12 + Date.current.month) -
     (last_update.month * 12 + last_update.year)).positive?
  end

  protected

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    admin? && (!persisted? || !password.nil? || !password_confirmation.nil?)
  end

  def create_badges_tracker
    self.badges_tracker = {
      sign_in_date: Date.current,
      daily_login_count: 0,
      total_reports: 0,
      total_unique: 0,
      total_list: [],
      beach_reports: 0,
      beach_unique: 0,
      beach_list: [],
      supermarket_reports: 0,
      supermarket_unique: 0,
      supermarket_list: [],
      pharmacy_reports: 0,
      pharmacy_unique: 0,
      pharmacy_list: [],
      restaurant_reports: 0,
      restaurant_unique: 0,
      restaurant_list: [],
      conquests_updated_at: nil,
      top_100: 0,
      top_50: 0,
      top_10: 0,
      top_1: 0
    }
  end

  def add_badges
    diff = changes_to_save['badges_tracker']
    diff_arr = diff.last.reject { |k, v| v == diff.first[k] }

    Badge.where.not(id: user_badges.pluck(:badge_id)).where(counter: diff_arr.keys).find_each do |b|
      if diff_arr[b.counter] >= b.target
        self.badges_won = badges_won + ' ' + b.slug
        badges << b
      end
    end
  end
end
