# frozen_string_literal: true

include FactoryBot::Syntax::Methods

create(:player,
       email: 'gdonald@gmail.com',
       name: 'gdonald',
       password: 'rapture17',
       password_confirmation: 'rapture17',
       confirmed_at: Time.current)

x = 0
%w[BarneyBot BettyBot WilmaBot FredBot].each do |name|
  x += 1
  pwd = Player.generate_password(16)
  email = "#{name}@nauticalwar.com"
  player = create(:player,
                  bot: true,
                  strength: x,
                  name: name,
                  email: email,
                  password: pwd,
                  password_confirmation: pwd,
                  confirmed_at: Time.current)
end

Game.create_ships
