# frozen_string_literal: true

class Api::V1::SessionsController < ApplicationController
  before_action :authenticate_user!, only: ['destroy']
  def create
    user = User.find_by_email(session_params[:email])
    if user&.valid_password?(session_params[:password])
      render_api_success(serializer, user)
    else
      render_api_error('Invalid email or password', 401)
    end
  end

  def destroy; end

  private

  def serializer
    SessionsSerializer
  end

  def session_params
    params.permit(:email, :password)
  end
end
