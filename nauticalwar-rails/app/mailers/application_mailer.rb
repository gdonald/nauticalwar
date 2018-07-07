# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'support@nauticalwar.com'
  layout 'mailer'
end
