# frozen_string_literal: true

def login(player)
  allow(request.env['warden']).to receive(:authenticate!) { player }
  allow(controller).to receive(:current_api_player) { player }
end

def admin_login(admin)
  visit new_player_session_path
  fill_in 'Email', with: admin.email
  fill_in 'Password', with: 'changeme'
  click_button 'Login'
  expect(page).to have_css('div.flash', text: 'Signed in successfully')
end
