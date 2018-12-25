# frozen_string_literal: true

require 'bcrypt'

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match?(value)

    record.errors[attribute] << (options[:message] || 'is not valid')
  end
end

class Player < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include BCrypt

  validates :email, presence: true, uniqueness: true, email: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 12 }
  validates :bot, inclusion: [true, false]

  validates :password,
            confirmation: true,
            presence: true,
            length: { maximum: 16 },
            if: :pass_req?
  validates :password_confirmation, presence: true, if: :pass_req?
  validates :p_salt, length: { maximum: 80 }
  validates :p_hash, length: { maximum: 80 }

  before_save :downcase_email
  before_save :set_confirmation_token
  after_create :send_confirmation_email

  has_many :games_1, foreign_key: :player_1_id, class_name: 'Game'
  has_many :games_2, foreign_key: :player_2_id, class_name: 'Game'

  has_many :moves

  has_many :invites_1, foreign_key: :player_1_id, class_name: 'Invite'
  has_many :invites_2, foreign_key: :player_2_id, class_name: 'Invite'

  has_many :friends, foreign_key: :player_1_id, class_name: 'Friend'
  has_many :enemies, foreign_key: :player_1_id, class_name: 'Enemy'

  scope :active, -> { where.not(confirmed_at: nil) }
  scope :not_bot, -> { where(bot: false) }

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

  def create_enemy!(id)
    if !enemies_player_ids.include?(id) && !friends_player_ids.include?(id)
      player = Player.active.not_bot.find_by(id: id)
      if player
        enemies.create!(player_2: player)
        return player.id
      end
    end
    -1
  end

  def enemies_player_ids
    enemies.collect(&:player_2_id)
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
    if !friends_player_ids.include?(id) && !enemies_player_ids.include?(id)
      player = Player.active.find_by(id: id)
      if player
        friends.create!(player_2: player)
        return player.id
      end
    end
    -1
  end

  def friends_player_ids
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
    query = Player.select(:id).where.not(id: player.enemies_player_ids)
    ids += query.where(arel_table[:rating].gteq(player.rating))
                .order(rating: :asc).limit(15).collect(&:id)
    ids += query.where(arel_table[:rating].lteq(player.rating))
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

  def reset_password_token
    self.password_token = Player.generate_unique_secure_token
    self.password_token_expire = Time.zone.now + 1.hour
    save!
  end

  def self.reset_password(params) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
    player = Player.find_by(password_token: params[:token])
    if player.nil?
      { id: -1 }
    elsif player.password_token_expire < Time.zone.now
      { id: -2 }
    elsif params[:password] != params[:password_confirmation]
      { id: -3 }
    else
      player.password = params[:password]
      player.password_confirmation = params[:password_confirmation]
      player.save!
      PlayerMailer.with(player: player).reset_complete_email.deliver_now
      { id: player.id }
    end
  end

  def self.locate_account(params)
    player = Player.find_by(email: params[:email])
    if player
      player.reset_password_token
      PlayerMailer.with(player: player).reset_email.deliver_now
      { id: player.id }
    else
      { id: -1 }
    end
  end

  def self.params_with_password(params)
    pwd = Player.generate_password(16)
    params[:password] = pwd
    params[:password_confirmation] = pwd
    params
  end

  def self.create_google_account(params)
    player = Player.create(Player.params_with_password(params))
    if player.valid?
      now = Time.zone.now
      player.update_attributes(confirmed_at: now, last_sign_in_at: now)
    end
    player
  end

  def self.complete_google_signup(params)
    player = Player.create_google_account(params)
    if player.valid?
      { id: player.id }
    else
      { errors: player.errors }
    end
  end

  def self.create_player(params)
    player = Player.create(params)
    if player.valid?
      { id: player.id }
    else
      { errors: player.errors }
    end
  end

  def self.authenticate_admin(params)
    admin = Player.find_by(admin: true, email: params[:email])
    return { error: 'Admin not found' } if admin.nil?

    if Player.hash_password(params[:password], admin.p_salt) == admin.p_hash
      { id: admin.id }
    else
      { error: 'Login failed' }
    end
  end

  def self.authenticate(params)
    player = Player.find_by(email: params[:email])
    return { error: 'Player not found' } if player.nil?

    if Player.hash_password(params[:password], player.p_salt) == player.p_hash
      player.update_attributes(last_sign_in_at: Time.zone.now)
      { id: player.id }
    else
      { error: 'Login failed' }
    end
  end

  def self.confirm_email(token)
    player = Player.find_by(confirmation_token: token)
    return unless player

    player.update_attributes(confirmed_at: Time.zone.now)
  end

  attr_reader :password

  def password=(passwd)
    @password = passwd
    return if passwd.blank?

    self.p_salt = Player.salt
    self.p_hash = Player.hash_password(@password, p_salt)
  end

  def self.salt
    BCrypt::Engine.generate_salt
  end

  def self.hash_password(password, salt)
    BCrypt::Engine.hash_secret(password, salt)
  end

  private

  def pass_req?
    p_hash.blank? || password
  end

  def downcase_email
    self.email = email.downcase
  end

  def set_confirmation_token
    self.confirmation_token = Player.generate_unique_secure_token
  end

  def send_confirmation_email
    PlayerMailer.with(player: self).confirmation_email.deliver_now
  end
end
