# frozen_string_literal: true

class PlayerMailer < ApplicationMailer
  def confirmation_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Signup')
  end

  def confirmation_complete_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Account Confirmation')
  end

  def reset_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Password Reset')
  end

  def reset_complete_email
    @player = params[:player]
    mail(to: @player.email, subject: 'Nautical War Password Reset Complete')
  end
end
