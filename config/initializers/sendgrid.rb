# frozen_string_literal: true

ActionMailer::Base.smtp_settings = {
  user_name: 'apikey',
  password: '', # api key
  domain: 'info@example.com',
  address: 'smtp.sendgrid.net',
  port: 587,
  authentication: :plain,
  enable_starttls_auto: true
}
