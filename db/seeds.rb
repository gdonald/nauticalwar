# frozen_string_literal: true

include FactoryBot::Syntax::Methods # rubocop:disable Style/MixinUsage

create(:player, :admin,
       email: 'gdonald@gmail.com', name: 'gdonald',
       password: 'changeme17', password_confirmation: 'changeme17',
       confirmed_at: Time.current)

x = 0
%w[Bender Johnny_5 Irona Eve].each do |name|
  x += 1
  pwd = Player.generate_password(16)
  email = "#{name}@nauticalwar.com"
  create(:player, :bot,
         strength: x, name:, email:,
         password: pwd, password_confirmation: pwd,
         confirmed_at: Time.current)
end

Game.create_ships

# create(:player,
#        email: 'gdonald+2@gmail.com', name: 'gdonald2',
#        password: 'changeme17', password_confirmation: 'changeme17',
#        confirmed_at: Time.current)
