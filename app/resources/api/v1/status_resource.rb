# == Schema Information
#
# Table name: statuses
#
#  id           :bigint           not null, primary key
#  updated_time :datetime         not null
#  valid_until  :datetime
#  status       :integer
#  queue        :integer
#  type         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  store_id     :bigint
#
module Api
  module V1
    class StatusResource < ApplicationResource
      abstract
      immutable

      MAX_STORES = 300

      attributes :updated_time, :valid_until, :status,
                 :queue, :store_id

      filter :store_id

      def updated_time
        @model.updated_time
      end

      def valid_until
        @model.valid_until || (@model.updated_time + 1.hour)
      end

      def status
        @model.status.nil? ? -1 : @model.status
      end

      def queue
        @model.queue.nil? ? -1 : @model.queue
      end

      filter :store_id, apply: ->(records, value, _options) {
        value = value[0...MAX_STORES]
        records.where(store_id: value)
      }
    end
  end
end
