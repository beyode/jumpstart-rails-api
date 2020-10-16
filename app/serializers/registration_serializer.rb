# frozen_string_literal: true

class RegistrationSerializer
  include JSONAPI::Serializer
  attributes :first_name, :last_name, :email
end
