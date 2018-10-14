# frozen_string_literal: true

include FactoryBot::Syntax::Methods

x = 0
%w[BarneyBot BettyBot WilmaBot FredBot].each do |name|
  x += 1
  pwd = Player.generate_password(16)
  email = "#{name}@nauticalwar.com"
  player = create(:player, bot: true, strength: x, name: name, email: email, password: pwd, password_confirmation: pwd, confirmed_at: Time.current)
end

create(:ship, name: 'Carrier',     size: 5)
create(:ship, name: 'Battleship',  size: 4)
create(:ship, name: 'Destroyer',   size: 3)
create(:ship, name: 'Submarine',   size: 3)
create(:ship, name: 'Patrol Boat', size: 2)
