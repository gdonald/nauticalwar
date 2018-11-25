# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::InvitesController < Api::ApiController
  skip_before_action :verify_authenticity_token,
                     only: %i[create cancel accept cancel]

  respond_to :json

  def index
    render json: current_api_player.invites.ordered
  end

  def count
    render json: { count: current_api_player.invites.count }
  end

  def create
    result = current_api_player.create_invite!(params)
    if result&.persisted?
      render json: result
    else
      render json: { errors: 'An error occured' }
    end
  end

  def accept
    game = current_api_player.accept_invite!(params[:id])
    if game&.persisted?
      klass = ActiveModelSerializers::SerializableResource
      render json: { invite_id: params[:id],
                     game: klass.new(game, {}).as_json,
                     player: klass.new(game.player_1, {}).as_json }
    else
      render json: { error: 'Invite not accepted' }
    end
  end

  def decline
    id = current_api_player.decline_invite!(params[:id])
    if id
      render json: { id: id }, status: :ok
    else
      render json: { error: 'Invite not found' }, status: :not_found
    end
  end

  def cancel
    id = current_api_player.cancel_invite!(params[:id])
    if id
      render json: { id: id }, status: :ok
    else
      render json: { error: 'Invite not found' }, status: :not_found
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
