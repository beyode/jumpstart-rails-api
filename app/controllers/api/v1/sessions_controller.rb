# frozen_string_literal: true

class Api::V1::SessionsController < ApplicationController
  before_action :authenticate_user, only: ['destroy']
  def create
    user = User.find_by_email(params[:email])
    render_json(serializer, user) if user&.valid_password?(params[:password])
  end

  def destroy; end

  private

  def serializer
    SessionsSerializer
  end

  def session_params
    params.require(:user).permit(:email, :password)
  end
end
