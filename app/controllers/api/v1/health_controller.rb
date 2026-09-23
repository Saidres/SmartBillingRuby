module Api
  module V1
    class HealthController < BaseController
      def show
        render_success({
          status: "healthy",
          environment: Rails.env,
          timestamp: Time.current.iso8601,
          database: database_connected?
        })
      end

      private

      def database_connected?
        ActiveRecord::Base.connection.active?
      rescue StandardError
        false
      end
    end
  end
end
