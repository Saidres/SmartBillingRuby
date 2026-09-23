module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
      rescue_from ActionController::ParameterMissing, with: :parameter_missing_response

      protected

      def render_success(data = {}, status: :ok)
        render json: { success: true, data: data }, status: status
      end

      def render_error(errors, status: :unprocessable_entity)
        render json: { success: false, errors: Array(errors) }, status: status
      end

      private

      def not_found_response(exception)
        render_error(exception.message, status: :not_found)
      end

      def parameter_missing_response(exception)
        render_error(exception.message, status: :bad_request)
      end
    end
  end
end
