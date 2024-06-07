# frozen_string_literal: true

class PlayerMailer < ApplicationMailer
  def invite_email
    @invite = params[:invite]
    @opponent = @invite.player2
    return if Unsub.found?(@opponent)

    @player = @invite.player1
    mail(to: @opponent.email, subject: 'Nautical War Invite')
  end

  def turn_notify_email
    @game = params[:game]
    @opponent = @game.opponent(@game.turn)
    return if Unsub.found?(@opponent)

    @player = @game.turn
    mail(to: @game.turn.email, subject: 'Nautical War Turn Notification')
  end

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
