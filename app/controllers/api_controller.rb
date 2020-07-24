class ApiController < ApplicationController
  include JSONAPI::ActsAsResourceController

  rescue_from TooManyRequestsError, with: :too_many_requests

  skip_before_action :set_current_user
  skip_before_action :authenticate_user!
  before_action :authenticate_with_jwt!

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def context
    {current_user: current_user, app_uuid: app_uuid}
  end

  private

  def authenticate_with_jwt!
    return @current_user = User.first if Rails.env.development?

    payload = JwtService.decode(token: token)
    if DateTime.parse(payload['expiration_date']) <= DateTime.current
      render json: {error: 'Auth token has expired. Please login again'}, status: :unauthorized
    elsif store_owner_code
      @current_user = User.where(store_owner_code: store_owner_code, role: :store_owner).first
    else
      @current_user = User.find_or_create_by(app_uuid: payload['uuid'])
    end
  rescue StandardError
    render json: {error: 'not authorized'}, status: :unauthorized
  end

  def current_user
    @current_user ||= if store_owner_code
                        User.find_by(store_owner_code: store_owner_code, role: :store_owner)
                      else
                        tmp_uuid = JwtService.decode(token: token)['uuid']
                        tmp_uuid.present? ? User.find_by(app_uuid: tmp_uuid) : nil
                      end
  rescue StandardError
    @current_user = nil
  end

  def app_uuid
    JwtService.decode(token: token)['uuid']
  rescue StandardError
    nil
  end

  def token
    request.headers.fetch('Authorization', '').split(' ').last
  end

  def store_owner_code
    request.headers.fetch('StoreOwnerCode', '').presence
  end

  def too_many_requests
    render json: {error: 'Too many requests'}, status: :too_many_requests
  end

  def api_key
    request.headers.fetch('ApiKey', '').presence
  end
end
