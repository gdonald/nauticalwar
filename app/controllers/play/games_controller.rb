# frozen_string_literal: true

class Play::GamesController < Play::PlayController
  before_action :get_current_player
  before_action :game, only: %i[show opponent layout attack my_turn]

  def index
    @games = @current_player.active_games.ordered
  end

  # shows all player ships, opponent attacks player
  def show
    @layouts = []
    @game.layouts_for_player(@current_player).each do |l|
      name = l.ship.name.downcase.gsub(/ /, '_')
      @layouts << "{ col: #{l.x}, row: #{l.y}, size: #{l.ship.size}, vertical: #{l.vertical}, name: '#{name}', img_h: #{name}, img_v: #{name}_vertical }"
    end
    @layouts = @layouts.join(',')

    @moves = []
    @game.moves_for_player(@game.opponent(@current_player)).ordered.each do |m|
      @moves << "{ col: #{m.x}, row: #{m.y}, hit: #{m.layout.present?} }"
    end
    @moves = @moves.join(',')

    @my_turn = @game.turn == @current_player
    @game_over = @game.winner.present?
  end

  # shows only sunk opponent ships, player attacks opponent
  def opponent
    @layouts = []
    @game.layouts_for_player(@game.opponent(@current_player)).each do |l|
      next unless l.sunk?

      name = l.ship.name.downcase.gsub(/ /, '_')
      @layouts << "{ col: #{l.x}, row: #{l.y}, size: #{l.ship.size}, vertical: #{l.vertical}, name: '#{name}', img_h: #{name}, img_v: #{name}_vertical }"
    end
    @layouts = @layouts.join(',')

    @moves = []
    @game.moves_for_player(@current_player).ordered.each do |m|
      @moves << "{ col: #{m.x}, row: #{m.y}, hit: #{m.layout.present?} }"
    end
    @moves = @moves.join(',')

    @can_attack = @game.can_attack?(@current_player)
    @my_turn = @game.turn == @current_player
    @game_over = @game.winner.present?
  end

  def layout; end

  def attack
    @layouts = ''
    @moves = ''

    return unless @game.can_attack?(@current_player)

    @current_player.attack!(@game, params)

    @layouts = []
    @moves = []

    opponent = @game.opponent(@current_player)
    @game.layouts_for_player(opponent).each do |l|
      next unless l.sunk?

      name = l.ship.name.downcase.gsub(/ /, '_')
      @layouts << "{ col: #{l.x}, row: #{l.y}, size: #{l.ship.size}, vertical: #{l.vertical}, name: '#{name}', img_h: #{name}, img_v: #{name}_vertical }"
    end
    @layouts = @layouts.join(',')

    @game.moves_for_player(@current_player).ordered.each do |m|
      @moves << "{ col: #{m.x}, row: #{m.y}, hit: #{m.layout.present?} }"
    end
    @moves = @moves.join(',')

    @can_attack = @game.can_attack?(@current_player)

    # return if opponent.updated_at > 1.hour.ago
    #
    # PlayerMailer.with(game: @game).turn_notify_email.deliver_now
  end

  def cancel
    @game = @current_player.cancel_game!(params[:id])
  end

  def destroy
    @game = @current_player.destroy_game!(params[:id])
  end

  def my_turn
    @my_turn = @game.turn == @current_player
  end

  private

  def game
    @game ||= Game.find_game(@current_player, params[:id])
    # TODO: 404
    raise 'Game not found' unless @game
  end
end
