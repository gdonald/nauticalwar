# frozen_string_literal: true

class Player < ApplicationRecord # rubocop:disable Metrics/ClassLength
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 12 }
  validates :bot, inclusion: [true, false]

  has_many :games_1, foreign_key: :player_1_id, class_name: 'Game'
  has_many :games_2, foreign_key: :player_2_id, class_name: 'Game'

  has_many :invites_1, foreign_key: :player_1_id, class_name: 'Invite'
  has_many :invites_2, foreign_key: :player_2_id, class_name: 'Invite'

  has_many :friends, foreign_key: :player_1_id, class_name: 'Friend'

  scope :active, -> { where.not(confirmed_at: nil).where(locked_at: nil) }

  def to_s
    name
  end

  def find_game(id, opponent = false)
    game = Game.find_game(self, id)
    return nil unless game

    player = self == game.player_1 ? game.player_1 : game.player_2
    player = game.opponent(player) if opponent
    layouts = game.layouts.where(player: player).ordered
    moves = game.moves_for_player(game.opponent(player)).ordered
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
