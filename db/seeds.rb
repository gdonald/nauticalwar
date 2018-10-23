# frozen_string_literal: true

include FactoryBot::Syntax::Methods # rubocop:disable Style/MixinUsage

create(:player, email: 'gdonald@gmail.com', name: 'gdonald',
                password: 'changeme17', password_confirmation: 'changeme17',
                confirmed_at: Time.current)

x = 0
%w[BarneyBot BettyBot WilmaBot FredBot].each do |name|
  x += 1
  pwd = Player.generate_password(16)
  email = "#{name}@nauticalwar.com"
  create(:player, bot: true, strength: x, name: name, email: email,
                  password: pwd, password_confirmation: pwd,
                  confirmed_at: Time.current)
end

Game.create_ships
