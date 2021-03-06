class ExternalApiController < ApplicationController
  skip_before_action :set_current_user
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :authenticate_with_api_key!
  protect_from_forgery with: :null_session

  private

  def authenticate_with_api_key!
    return @current_user = User.first if Rails.env.development?

    payload = JwtService.decode(token: token)
    if DateTime.parse(payload['expiration_date']) <= DateTime.current
      render json: {error: 'Auth token has expired. Please login again'}, status: :unauthorized
    else
      @current_user = ApiKey.find_by(access_token: token).user
    end
  rescue StandardError
    render json: {error: 'not authorized'}, status: :unauthorized
  end

  def current_user
    return @current_user = User.find_by(role: :admin) if Rails.env.development?

    @current_user ||= ApiKey.find_by(access_token: token).user
  rescue StandardError
    @current_user = nil
  end

  def token
    request.headers.fetch('Authorization', '').split(' ').last
  end

  def api_key
    request.headers.fetch('ApiKey', '').presence
  end
end
