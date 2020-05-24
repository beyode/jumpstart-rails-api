# frozen_string_literal: true

class ApplicationController < ActionController::API
  around_action :handle_errors

  def render_api_success(serializer, obj, _options = {})
    render json: serializer.new(obj).serializable_hash
  end

  def render_api_error(messages, code)
    data = { errors: { code: code, details: Array.wrap(messages) } }
    render json: data, status: code
  end

  def handle_errors
    yield
  rescue ActiveRecord::RecordNotFound => e
    render_api_error(e.message, 404)
  rescue ActiveRecord::RecordInvalid => e
    render_api_error(e.record.errors.full_messages, 422)
  rescue ::JWT::ExpiredSignature => e
    render_api_error(e.message, 401)
  rescue ::JWT::DecodeError => e
    render_api_error(e.message, 401)
  rescue ActionController::ParameterMissing => e
    render_api_error(e.message, 400)
  end
end
