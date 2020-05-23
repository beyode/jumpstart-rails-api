# frozen_string_literal: true

class ApplicationController < ActionController::API
  around_action :handle_errors
  def render_api_json(serializer, obj, _options = {})
    render json: serializer.new(obj).serialized_hash
  end

  def handle_errors
    yield
  rescue ActiveRecord::RecordNotFound => e
    render_api_error(e.message, 404)
  rescue ActiveRecord::RecordInvalid => e
    render_api_error(e.record.errors.full_messages, 422)
  rescue JWT::ExpiredSignature => e
    render_api_error(e.message, 401)
  rescue InvalidTokenError => e
    render_api_error(e.message, 422)
  rescue MissingTokenError => e
    render_api_error(e.message, 422)
  end

  def render_api_error(messages, code)
    data = { errors: { code: code, details: Array.wrap(messages) } }
    render json: data, status: code
  end
end
