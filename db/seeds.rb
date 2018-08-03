
include FactoryBot::Syntax::Methods

x = 0
%w[BarneyBot BettyBot WilmaBot FredBot].each do |username|
  x += 1
  pwd = User.generate_password(16)
  email = "#{username}@nauticalwar.com"
  user = create(:user, bot: true, strength: x, username: username, email: email, password: pwd, password_confirmation: pwd)
end

create(:ship, name: 'Carrier',     size: 5)
create(:ship, name: 'Battleship',  size: 4);
create(:ship, name: 'Destroyer',   size: 3);
create(:ship, name: 'Submarine',   size: 3);
create(:ship, name: 'Patrol Boat', size: 2);
