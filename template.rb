# frozen_string_literal: true

# Gems
def add_gems
  gem 'devise'
  gem 'jwt'
  gem 'fast_json'
  gem 'dotenv-rails'
  gem 'sidekiq'
  gem 'whenever'
  gem 'mini_magik'

  gem_group :development, :test do
    gem 'guard'
    gem 'vcr'
  end
end

def install_devise
  generate 'devise:install'
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  generate :devise, 'User', 'first_name:string', 'last_name:string', 'admin:boolean'
  route "root to: 'home#index'"
  gsub_file 'config/initializers/devise.rb',
            /  # config.secret_key = .+/,
            '  config.secret_key = Rails.application.credentials.secret_key_base'
end

def device_jwt_strategy
  content = <<-RUBY
  config.warden do |manager|
  #manager.intercept_401 = false
  manager.strategies.add :jwt, Devise::Strategies::JWT
  manager.default_strategies(scope: :user).unshift :jwt
  manager.failure_app = CustomFailure::CustomFailureApp
  end
  RUBY

  insert_into_file('config/initializers/devise.rb',
                   "#{content}\n\n", before: '# ==> Mountable engine configurations')

  append_to_file 'config/initializers/devise.rb' do
    "
module Devise
  module Strategies
    class JWT < Base
      def valid?
        request.headers['Authorization'].present?
      end

      def authenticate!
        token = request.headers.fetch('Authorization', '').split(' ').last
        payload = JsonWebToken.decode(token)
        success! User.find(payload['sub'])
      rescue ::JWT::ExpiredSignature
        fail! 'Expired Token'
      rescue ::JWT::DecodeError
        fail! 'auth Token invalid'
      end
    end
  end
end

module CustomFailure
  class CustomFailureApp < Devise::FailureApp
    def respond
      if request.format == :json
        json_error_response
      else
        super
      end
    end

    def json_error_response
      self.status = 401
      self.content_type = 'application/json'
      self.response_body = [{ message: i18n_message }].to_json
    end
  end
end
    "
  end
end

after_bundle do
  git :init
  git add: '.'
  git commit: %( -m 'Initial commit')
end
