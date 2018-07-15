
include FactoryBot::Syntax::Methods

%w[FredBot WilmaBot BarneyBot BettyBot].each do |username|
  pwd = User.generate_password(16)
  email = "#{username}@nauticalwar.com"
  user = create(:user, username: username, email: email, password: pwd, password_confirmation: pwd)
  create(:bot, user: user)
end

create(:ship, name: 'Carrier',     size: 5 )
create(:ship, name: 'Battleship',  size: 4 );
create(:ship, name: 'Destroyer',   size: 3 );
create(:ship, name: 'Submarine',   size: 3 );
create(:ship, name: 'Patrol Boat', size: 2 );
