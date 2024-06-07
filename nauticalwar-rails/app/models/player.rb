# frozen_string_literal: true

require 'bcrypt'

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match?(value)

    record.errors.add(attribute, options[:message] || 'is not valid')
  end
end

class Player < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include BCrypt

  WATERS = { 0 => 'blue', 1 => 'green', 3 => 'red', 2 => 'grey' }.freeze
  GRIDS = { 0 => 'blue', 1 => 'green', 2 => 'red' }.freeze

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
  before_create :set_unsub_hash
  before_create :set_confirmation_token, unless: -> { guest? }
  after_create :send_confirmation_email, unless: -> { guest? }

  has_many :games1, foreign_key: :player1_id, class_name: 'Game', dependent: :destroy, inverse_of: :player1
  has_many :games2, foreign_key: :player2_id, class_name: 'Game', dependent: :destroy, inverse_of: :player2

  has_many :moves, dependent: :destroy

  has_many :invites1, foreign_key: :player1_id, class_name: 'Invite', dependent: :destroy, inverse_of: :player1
  has_many :invites2, foreign_key: :player2_id, class_name: 'Invite', dependent: :destroy, inverse_of: :player2

  has_many :friends, foreign_key: :player1_id, class_name: 'Friend', dependent: :destroy, inverse_of: :player1
  has_many :enemies, foreign_key: :player1_id, class_name: 'Enemy', dependent: :destroy, inverse_of: :player1

  scope :active, -> { where.not(confirmed_at: nil).or(is_guest) }
  scope :is_guest, -> { where(guest: true) }
  scope :not_bot, -> { where(bot: false) }
  scope :not_self, ->(id) { where.not(id:) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[activity admin bot confirmation_token confirmed_at created_at email grid guest hints id id_value last_sign_in_at
       losses name p_hash p_salt password_token password_token_expire rating strength unsub_hash updated_at water wins]
  end

  def to_s
    name
  end

  def admin?
    admin
  end

  def cancel_invite!(id)
    invite_id = nil
    invite = invites1.find_by(id:)
    if invite
      invite_id = invite.id
      invite.destroy
    end
    invite_id
  end

  def decline_invite!(id)
    invite_id = nil
    invite = invites2.find_by(id:)
    if invite
      invite_id = invite.id
      invite.destroy
    end
    invite_id
  end

  def accept_invite!(id)
    invite = invites2.find_by(id:)
    if invite
      game = invite.create_game
      invite.destroy
    end
    game
  end

  def invite_args(params)
    { player2: Player.active.not_self(id).where(id: params[:id]).first,
      rated: params[:r] == '1',
      shots_per_turn: params[:s].to_i,
      time_limit: params[:t].to_i }
  end

  def create_opponent_invite!(args)
    invites1.create(args)
  end

  def create_bot_game!(args)
    args[:turn] = self
    game = games1.create(args)
    game.bot_layout if game.persisted?
    game
  end

  def create_invite!(params)
    args = invite_args(params)
    return unless args[:player2]

    if args[:player2].bot
      create_bot_game!(args)
    else
      invite = create_opponent_invite!(args)
      PlayerMailer.with(invite:).invite_email.deliver_now
      invite
    end
  end

  def self.create_guest
    player = nil
    while player.nil?
      r = 7.times.collect { rand(0..9) }.join
      name = "Guest#{r}"
      email = "#{name}@nauticalwar.com"
      player = Player.create(guest: true, name:, email:)
      player = nil unless player.valid?
    end
    player
  end

  def create_guest_bot_game
    args = { player2: Player.where(bot: true).sample, rated: true, shots_per_turn: 5, time_limit: 300 }
    game = create_bot_game!(args)
    game.guest_layout
    game
  end

  # TODO: add to android
  def destroy_enemy!(id)
    enemy = enemies.where(player2_id: id).first
    if enemy
      player2_id = enemy.player2_id
      enemy.destroy
      return player2_id
    end
    -1
  end

  def create_enemy!(id)
    if enemies_player_ids.exclude?(id) && friends_player_ids.exclude?(id)
      player = Player.active.not_bot.not_self(self.id).find_by(id:)
      if player
        enemies.create!(player2: player)
        return player.id
      end
    end
    -1
  end

  def enemies_player_ids
    enemies.collect(&:player2_id)
  end

  def destroy_friend!(id)
    friend = friends.where(player2_id: id).first
    if friend
      player2_id = friend.player2_id
      friend.destroy
      return player2_id
    end
    -1
  end

  def create_friend!(id)
    if friends_player_ids.exclude?(id) && enemies_player_ids.exclude?(id)
      player = Player.active.not_self(self.id).find_by(id:)
      if player
        friends.create!(player2: player)
        return player.id
      end
    end
    -1
  end

  def friends_list
    friends.collect(&:player2)
  end

  def friends_player_ids
    friends.collect(&:player2_id)
  end

  def friend?(player_id)
    friends.find_by(player2_id: player_id).present?
  end

  def enemy?(player_id)
    enemies.find_by(player2_id: player_id).present?
  end

  def new_activity!
    new_activity = activity + 1
    update(activity: new_activity)
  end

  def record_shot!(game, col, row)
    return if game.move_exists?(self, col, row)

    layout = game.hit?(game.opponent(self), col, row)
    moves.create!(game:, x: col, y: row, layout:)
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
    { game:, layouts:, moves: }
  end

  def opponent_game(id)
    game = Game.find_game(self, id)
    return nil unless game

    layouts = game.layouts_for_opponent(game.opponent(self))
    moves = game.moves_for_player(self).ordered
    { game:, layouts:, moves: }
  end

  def my_turn(id)
    game = Game.find_game(self, id)
    game && game.turn == self ? 1 : -1
  end

  def cancel_game!(id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    game = Game.find_game(self, id)
    if game
      if game.t_limit.negative?
        # layouts
        if self == game.player1
          if game.player1_layed_out && !game.player2_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player1)
          elsif !game.player1_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player2)
          end
        elsif self == game.player2
          if game.player2_layed_out && !game.player1_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player2)
          elsif !game.player2_layed_out # rubocop:disable Metrics/BlockNesting
            game.make_winner!(game.player1)
          end
        end

        if game.winner.nil? && self == game.turn # player is giving up
          winner = self == game.player1 ? game.player2 : game.player1 # rubocop:disable Metrics/BlockNesting
          game.make_winner!(winner)
        end

        if game.winner.nil? && self != game.turn # opponent won't play
          winner = self == game.player1 ? game.player1 : game.player2 # rubocop:disable Metrics/BlockNesting
          game.make_winner!(winner)
        end
      else
        winner = self == game.player1 ? game.player2 : game.player1
        game.make_winner!(winner)
      end
      game.calculate_scores(cancel: true)
    end
    game
  end

  def destroy_game!(id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    game = Game.find_game(self, id)
    if game&.winner
      if game.player2.bot
        game.destroy
      else
        if game.player1 == self
          game.update(del_player1: true)
        elsif game.player2 == self
          game.update(del_player2: true)
        end
        game.destroy if game.del_player1 && game.del_player2
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
                       player1_layed_out: true,
                       player2_layed_out: true).order(updated_at: :desc)
  end

  def active_games
    games1.includes(%i[player1 player2])
          .where(del_player1: false)
          .or(games2.includes(%i[player1 player2])
                .where(del_player2: false))
  end

  def invites
    invites1.or(invites2)
  end

  def self.list_for_game(game_id)
    game = Game.find_by(id: game_id)
    ids = game.nil? ? [] : [game.player1_id, game.player2_id]
    Player.where(id: ids)
  end

  def self.guest_search(player, name)
    ids = [player.id]
    ids += Player.where(bot: true).pluck(:id)
    ids.uniq!

    Player.where(id: ids).where('name ILIKE ?', "%#{name}%")
          .order(rating: :desc)
          .limit(30)
  end

  def self.search(name)
    Player.where('name ILIKE ?', "%#{name}%")
          .where.not(confirmed_at: nil)
          .where.not(guest: true)
          .order(rating: :desc)
          .limit(30)
  end

  def self.guest_list(player)
    ids = [player.id]
    ids += Player.where(bot: true).pluck(:id)
    ids.uniq!
    Player.where(id: ids).order(rating: :desc)
  end

  def self.list(player) # rubocop:disable Metrics/AbcSize
    ids = [player.id]
    ids += Player.where(bot: true).pluck(:id)
    query = Player.select(:id).where.not(id: player.enemies_player_ids).where.not(guest: true)
    ids += query.where(arel_table[:rating].gteq(player.rating))
                .order(rating: :asc).limit(15).collect(&:id)
    ids += query.where(arel_table[:rating].lteq(player.rating))
                .order(rating: :desc).limit(15).collect(&:id)
    ids.uniq!
    Player.where(id: ids).where.not(confirmed_at: nil).order(rating: :desc)
  end

  def self.generate_password(length)
    chars = (('a'..'z').to_a + (0..9).to_a + (%w[! @ # $ % ^ & * ( ) - _] * 10))
    chars.shuffle[0, length].join
  end

  def last
    return 0 if bot

    if updated_at
      return 0 if updated_at > 1.hour.ago
      return 1 if updated_at > 1.day.ago
      return 2 if updated_at > 3.days.ago
    end
    3
  end

  def reset_password_token
    self.password_token = Player.generate_unique_secure_token
    self.password_token_expire = 1.hour.from_now
    save!
  end

  def self.reset_password(params) # rubocop:disable Metrics/AbcSize
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
      player.password_token = nil
      player.password_token_expire = nil
      player.save!
      PlayerMailer.with(player:).reset_complete_email.deliver_now
      { id: player.id }
    end
  end

  def self.confirm_account(params)
    player = Player.find_by(email: params[:email])
    if player
      player.update(confirmation_token: Player.generate_unique_secure_token)
      PlayerMailer.with(player:).confirmation_email.deliver_now
      { id: player.id }
    else
      { id: -1 }
    end
  end

  def self.locate_account(params)
    player = Player.find_by(email: params[:email])
    if player
      player.reset_password_token
      PlayerMailer.with(player:).reset_email.deliver_now
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
    Player.create(Player.params_with_password(params))
  end

  def self.complete_google_signup(params)
    player = Player.create_google_account(params)
    if player.valid?
      { id: player.id }
    else
      { errors: player.errors }
    end
  end

  def convert_guest_to_player(params)
    params.merge!(guest: false)

    downcase_email
    set_confirmation_token

    if update(params)
      send_confirmation_email
      { id: }
    else
      { errors: }
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
    return { error: 'Email not confirmed' } unless player.confirmed_at

    if Player.hash_password(params[:password], player.p_salt) == player.p_hash
      player.update(last_sign_in_at: Time.zone.now)
      { id: player.id }
    else
      { error: 'Login failed' }
    end
  end

  def self.confirm_email(token)
    player = Player.find_by(confirmation_token: token)
    return unless player

    player if player.update(confirmed_at: Time.zone.now)
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

  def last_color
    case last
    when 0
      'green'
    when 1
      'blue'
    when 2
      'orange'
    else
      'red'
    end
  end

  def rank # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    case rating
    when 700..800
      'e2'
    when 800..900
      'e3'
    when 900..1000
      'e4'
    when 1000..1100
      'e5'
    when 1100..1200
      'e6'
    when 1200..1300
      'e7'
    when 1300..1400
      'e8'
    when 1400..1500
      'e9'
    when 1500..1600
      'o1'
    when 1600..1700
      'o2'
    when 1700..1800
      'o3'
    when 1800..1850
      'o4'
    when 1850..1900
      'o5'
    when 1900..1950
      'o6'
    when 1950..2000
      'o7'
    when 2000..2050
      'o8'
    when 2050..2100
      'o9'
    when 2100..2150
      'o10'
    when 2150..Integer.MAX
      'o11'
    else
      'e1'
    end
  end

  private

  def pass_req?
    return false if guest?

    p_hash.blank? || password
  end

  def downcase_email
    self.email = email.downcase
  end

  def set_unsub_hash
    self.unsub_hash = Player.generate_unique_secure_token
  end

  def set_confirmation_token
    self.confirmation_token = Player.generate_unique_secure_token
  end

  def send_confirmation_email
    PlayerMailer.with(player: self).confirmation_email.deliver_now
  end
end
