# frozen_string_literal: true

module Play
  class InvitesController < Play::PlayController
    before_action :set_current_player

    def index
      @invites = @current_player.invites.ordered
    end

    def create
      @result = @current_player.create_invite!(params)
    end

    def accept
      @game = @current_player.accept_invite!(params[:id])
    end

    def decline
      @id = @current_player.decline_invite!(params[:id])
    end

    def cancel
      @id = @current_player.cancel_invite!(params[:id])
    end
  end
end
