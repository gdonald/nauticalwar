# frozen_string_literal: true

class PlayerMailer < ApplicationMailer
  def confirmation_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Signup')
  end

  def reset_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Password Reset')
  end
end
