module Api
  module V1
    class StoreResource < ApplicationResource
      immutable
      #caching

      has_one :current_day, class_name: 'WeekDay', exclude_links: :default

      attributes :name, :group, :address, :coordinates, :capacity,
                 :details, :store_type, :lonlat, :opening_hour, :closing_hour

      filters :location, :store_type

      filter :location, apply: ->(records, value, options) {
        current_user = options[:context][:current_user]
        if current_user&.store_owner?
          current_user.stores.retrieve_stores(value.first, value.second)
        else
          records.retrieve_stores(value.first, value.second)
        end
      }

      def address
        @model.address(unique: true)
      end

      def coordinates
        [@model.latitude, @model.longitude]
      end

      def opening_hour
        @model.current_day&.opening_hour
      end

      def closing_hour
        @model.current_day&.closing_hour
      end

      def self.records(options = {})
        current_user = options[:context][:current_user]
        if current_user&.store_owner?
          current_user.stores.available
        else
          super(options).available.includes(:week_days)
        end
      end

      exclude_links :default
    end
  end
end
