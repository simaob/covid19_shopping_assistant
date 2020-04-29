# frozen_string_literal: true

module UserPostable
  extend ActiveSupport::Concern

  USER_INTERVAL = 0.30

  def validate_user_interval
    current_user = context[:current_user]
    return if current_user.admin?
    return if current_user.last_post.nil?
    return if current_user.last_post.utc < (Time.current - USER_INTERVAL.minutes)

    raise TooManyRequestsError
  end

  def update_user_time
    context[:current_user].update last_post: DateTime.current
  end
end
