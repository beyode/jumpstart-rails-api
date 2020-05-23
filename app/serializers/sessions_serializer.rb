# frozen_string_literal: true

class SessionsSerializer
  include FastJsonapi::ObjectSerializer
  attributes :email, :jwt

  attribute :jwt_token do |object|
    JsonWebToken.encode(sub: object.id)
  end
end
