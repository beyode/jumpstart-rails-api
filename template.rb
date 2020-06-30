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
  gem 'simple_token_authentication', '~> 1.17'

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
  # route "root to: 'home#index'"
  gsub_file 'config/initializers/devise.rb',
            /  # config.secret_key = .+/,
            '  config.secret_key = Rails.application.credentials.secret_key_base'
end

def devise_jwt_strategy
  # comment devise generated routes
  comment_lines 'config/routes.rb', 'devise_for :users'

  # add custom routes
  insert_into_file 'config/routes.rb', after: 'Rails.application.routes.draw do' do
    "
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        devise_for :users, skip: :all, controllers: {
          sessions: 'api/v1/sessions'
        }
        devise_scope :user do
          resources :registration, only: ['create']
          resources :sessions, only: %w[create destroy]
        end
        resources :posts
      end
    end
    "
  end

  # implement device strategy
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

  # add class used by strategy
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
          self.status = 401
          self.content_type = 'application/json'
          self.response_body = {
            errors: {
              code: '401',
              title: :unauthorized,
              detail: i18n_message
            }
          }.to_json
        end
      end
    end
  end
    "
  end
end

def device_simple_token_auth
  # authenticable model
  insert_into_file 'app/models/user.rb', after: 'class User < ApplicationRecord' do
    "
    acts_as_token_authenticatable
    "
  end

  # add token column
  generate(:migration, 'add_authentication_token_to_users', 'authentication_token:string{30}:uniq')

  # allow controller to handle authentication
  insert_into_file 'app/controllers/application_controller.rb', after: 'class ApplicationController < ActionController::API' do
    "
    acts_as_token_authentication_handler_for User
    "
  end
end

def auth_mode
  say
  if yes?('Use JWT instead of simple Token ?', :blue)
    devise_jwt_strategy
  else
    device_simple_token_auth
  end
end

def copy_templates
  copy_file 'Procfile'
  copy_file 'Procfile.dev'
  copy_file '.foreman'
  directory 'app', force: true
  directory 'config', force: true
end

def stop_spring
  run 'spring stop'
end

def install_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq', env: 'development'
end

# setup
add_template_repository_to_source_path

# Add gems
add_gems

after_bundle do
  stop_spring
  install_devise
  copy_templates
  install_sidekiq
  auth_mode
  # commit all to git
  git :init
  git add: '.'
  git commit: %( -m 'Initial commit')

  say
  say 'Application generated successfully', :blue
  say
  say "cd #{app_name} to switch to app", :blue
end
