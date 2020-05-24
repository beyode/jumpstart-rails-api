# frozen_string_literal: true

class Api::V1::RegistrationController < ApplicationController
  def create
    user = User.new(register_params)
    if user.save
      render_api_success(serializer, user)
    else
      render_api_error(user.errors.full_messages, 422)
    end
  end

  private

  def serializer
    RegistrationSerializer
  end

  def register_params
    params.permit(:first_name, :last_name, :email, :password)
  end
end
