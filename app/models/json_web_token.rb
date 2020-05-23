# frozen_string_literal: true

# JWT class
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base
  class << self
    def encode(payload)
      expiration = 24.hours.from_now.to_i
      JWT.encode(payload.merge(exp: expiration), SECRET_KEY)
    end

    def decode(token)
      JWT.decode(token, SECRET_KEY).first
    end
  end
end
