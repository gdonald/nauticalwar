class Play::PlayersController < Play::PlayController
  before_action :get_current_player, except: %i[new create lost locate reset_password]
  before_action :player, only: %i[show block unblock friend unfriend]
  before_action :friends, only: %i[index search show]

  def index
    @players = Player.list(@current_player).includes(:friends)
  end

  def search
    @players = Player.search(params[:q]).includes(:friends)
  end

  def show; end

  def block
    @current_player.create_enemy!(params[:id])
  end

  def unblock
    @current_player.destroy_enemy!(params[:id])
  end

  def friend
    @current_player.create_friend!(params[:id])
    friends
  end

  def unfriend
    @current_player.destroy_friend!(params[:id])
    friends
  end

  def new
    @player = Player.new
  end

  def create
    @player = Player.create(player_params)
    if @player.valid?
      flash[:notice] = 'Please confirm your email'
      redirect_to new_play_session_path
    else
      flash[:notice] = 'Signup failed'
      render :new
    end
  end

  def lost; end

  def locate
    Player.locate_account(locate_params)
    flash[:notice] = 'Please check your email'
    redirect_to play_games_path
  end

  def reset_password
    @token = params[:token]
    @player = Player.find_by(password_token: params[:token])
    if @player.nil? || @player.password_token_expire < Time.zone.now
      flash[:notice] = 'Invalid token'
      render 'reset'
    elsif params[:password].empty?
      flash[:notice] = 'Password required'
      render 'reset'
    elsif params[:password] != params[:password_confirmation]
      flash[:notice] = 'Password does not match confirmation'
      render 'reset'
    else
      @player.password = params[:password]
      @player.password_confirmation = params[:password_confirmation]
      @player.save!
      @player.password_token = nil
      @player.password_token_expire = nil
      @player.save!
      PlayerMailer.with(player: @player).reset_complete_email.deliver_now
      redirect_to new_play_session_path
    end
  end

  private

  def locate_params
    params.permit(:email)
  end

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def player
    @player ||= Player.find_by(id: params[:id])
  end

  def friends
    @friends ||= @current_player.friends_list
  end
end
