# frozen_string_literal: true

class Api::V1::RegistrationController < ApplicationContoller
  def create
    user = User.new(register_params)
    render_json(serializer, user) if user.save
  end

  private

  def serializer
    RegistrationSerializer
  end

  def register_params
    params.require(:user).permit(:first_name, :last_name, :email, :password)
  end
end
