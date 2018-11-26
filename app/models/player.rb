# frozen_string_literal: true

class Player < ApplicationRecord # rubocop:disable Metrics/ClassLength
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 12 }
  validates :bot, inclusion: [true, false]

  has_many :games_1, foreign_key: :player_1_id, class_name: 'Game'
  has_many :games_2, foreign_key: :player_2_id, class_name: 'Game'

  has_many :moves

  has_many :invites_1, foreign_key: :player_1_id, class_name: 'Invite'
  has_many :invites_2, foreign_key: :player_2_id, class_name: 'Invite'

  has_many :friends, foreign_key: :player_1_id, class_name: 'Friend'

  scope :active, -> { where.not(confirmed_at: nil).where(locked_at: nil) }

  def to_s
    name
  end

  def admin?
    admin
  end

  def cancel_invite!(id)
    invite_id = nil
    invite = invites_1.find_by(id: id)
    if invite
      invite_id = invite.id
      invite.destroy
    end
    invite_id
  end

  def decline_invite!(id)
    invite_id = nil
    invite = invites_2.find_by(id: id)
    if invite
      invite_id = invite.id
      invite.destroy
    end
    invite_id
  end

  def accept_invite!(id)
    invite = invites_2.find_by(id: id)
    if invite
      game = invite.create_game
      invite.destroy
    end
    game
  end

  def invite_args(params)
    { player_2: Player.active.where(id: params[:id]).first,
      rated: params[:r] == '1',
      five_shot: params[:m] == '0',
      time_limit: (params[:t] == '1' ? 3.days : 1.day).to_i }
  end

  def create_opponent_invite!(args)
    invites_1.create(args)
  end

  def create_bot_game!(args)
    args[:turn] = self
    game = games_1.create(args)
    game.bot_layout if game.persisted?
    game
  end

  def create_invite!(params)
    args = invite_args(params)
    return unless args[:player_2]

    if args[:player_2].bot
      create_bot_game!(args)
    else
      create_opponent_invite!(args)
    end
  end

  def destroy_friend!(id)
    friend = friends.where(player_2_id: id).first
    if friend
      player_2_id = friend.player_2_id
      friend.destroy
      return player_2_id
    end
    -1
  end

  def create_friend!(id)
    player = Player.active.find_by(id: id)
    if player && !friends.include?(player)
      friends.create!(player_2: player)
      return player.id
    end
    -1
  end

  def friend_ids
    friends.collect(&:player_2_id)
  end

  def new_activity!
    new_activity = activity + 1
    update_attributes(activity: new_activity)
  end

  def record_shot!(game, col, row)
    return if game.move_exists?(self, col, row)

    layout = game.hit?(game.opponent(self), col, row)
    moves.create!(game: game, x: col, y: row, layout: layout)
  end

  def record_shots!(game, json)
    shots = game.parse_shots(json)
    shots.each { |s| record_shot!(game, s['x'], s['y']).layout&.sunk? }
    game.next_turn!
  end

  def attack!(game, params)
    new_activity!
    record_shots!(game, params[:s])
    return if game.winner

    game.bot_attack! if game.opponent(self).bot
  end

  def player_game(id)
    game = Game.find_game(self, id)
    return nil unless game

    layouts = game.layouts_for_player(self)
    moves = game.moves_for_player(game.opponent(self)).ordered
    { game: game, layouts: layouts, moves: moves }
  end

  def opponent_game(id)
    game = Game.find_game(self, id)
    return nil unless game

    layouts = game.layouts_for_opponent(game.opponent(self))
    moves = game.moves_for_player(self).ordered
    { game: game, layouts: layouts, moves: moves }
  end

  def my_turn(id)
    game = Game.find_game(self, id)
    game && game.turn == self ? 1 : -1
  end

  def cancel_game!(id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    game = Game.find_game(self, id)
    if game
      if game.t_limit.negative?
        # layouts
        if self == game.player_1
          if game.player_1_layed_out && !game.player_2_layed_out # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
            game.make_winner!(game.player_1)
          elsif !game.player_1_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player_2)
          end
        elsif self == game.player_2
          if game.player_2_layed_out && !game.player_1_layed_out # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
            game.make_winner!(game.player_2)
          elsif !game.player_2_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player_1)
          end
        end

        if game.winner.nil? && self == game.turn # player is giving up
          winner = self == game.player_1 ? game.player_2 : game.player_1 # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
          game.make_winner!(winner)
        end

        if game.winner.nil? && self != game.turn # opponent won't play
          winner = self == game.player_1 ? game.player_1 : game.player_2 # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
          game.make_winner!(winner)
        end
      else
        winner = self == game.player_1 ? game.player_2 : game.player_1
        game.make_winner!(winner)
      end
      game.calculate_scores(true)
    end
    game
  end

  def destroy_game!(id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    game = Game.find_game(self, id)
    if game&.winner
      if game.player_2.bot
        game.destroy
      else
        if game.player_1 == self
          game.update_attributes(del_player_1: true)
        elsif game.player_2 == self
          game.update_attributes(del_player_2: true)
        end
        game.destroy if game.del_player_1 && game.del_player_2
      end
    end
    game
  end

  def can_skip?(game)
    game && game.winner.nil? && game.turn != self && game.t_limit <= 0
  end

  def skip_game!(id)
    game = Game.find_game(self, id)
    game.next_turn! if can_skip?(game)
    game
  end

  def next_game
    games = layed_out_and_no_winner
    game = games.where(turn: self).first
    return game if game

    games.each do |g|
      return g if g.turn != self && g.t_limit <= 0
    end

    nil
  end

  def layed_out_and_no_winner
    active_games.where(winner: nil,
                       player_1_layed_out: true,
                       player_2_layed_out: true).order(updated_at: :desc)
  end

  def active_games
    games_1.includes(%i[player_1 player_2])
           .where(del_player_1: false)
           .or(games_2.includes(%i[player_1 player_2])
                      .where(del_player_2: false))
  end

  def invites
    invites_1.or(invites_2)
  end

  def self.list(player) # rubocop:disable Metrics/AbcSize
    ids = Player.select(:id).where(bot: true).collect(&:id)
    ids += Player.select(:id).where(arel_table[:rating].gteq(player.rating))
                 .order(rating: :asc).limit(15).collect(&:id)
    ids += Player.select(:id).where(arel_table[:rating].lteq(player.rating))
                 .order(rating: :desc).limit(15).collect(&:id)
    ids.uniq!
    Player.where(id: ids).order(rating: :desc)
  end

  def self.generate_password(length)
    chars = (('a'..'z').to_a + (0..9).to_a + %w[! @ # $ % ^ & * ( ) - _] * 10)
    chars.shuffle[0, length].join
  end

  def last
    return 0 if bot

    if last_sign_in_at
      return 0 if last_sign_in_at > 1.hour.ago
      return 1 if last_sign_in_at > 1.day.ago
      return 2 if last_sign_in_at > 3.days.ago
    end
    3
  end
end
