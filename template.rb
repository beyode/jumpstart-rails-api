# frozen_string_literal: true

require 'fileutils'
require 'shellwords'

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('jumpstart-rails-api-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/beyode/jumpstart-rails-api.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{jumpstart-rails-api/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

# Gems
def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'jwt', '~> 2.2', '>= 2.2.1'
  gem 'fast_jsonapi', '~> 1.5'
  gem 'dotenv-rails', '~> 2.7', '>= 2.7.5'
  gem 'sidekiq', '~> 6.0', '>= 6.0.7'
  gem 'whenever', '~> 1.0'
  gem 'rack-cors'

  gem_group :development, :test do
    gem 'vcr', '~> 5.1'
    gem 'foreman', '~> 0.87.1'
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

def devise_jwt_strategy
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

def auth_mode
  auth = ask("\nWhich Authentication Method would you like to use\n
    1. Json Web Token(JWT)\n
    2. Simple token auth\n", :blue)

  devise_jwt_strategy if auth == '1'
end

def copy_templates
  directory 'app', force: true
  directory 'config', force: true
end

# setup
add_template_repository_to_source_path

# Add gems
add_gems

after_bundle do
  install_devise
  auth_mode
  copy_templates
  # commit all to git
  git :init
  git add: '.'
  git commit: %( -m 'Initial commit')

  say
  say 'Application generated successfully', :blue
  say
  say 'cd to the app to get started', :blue
end
