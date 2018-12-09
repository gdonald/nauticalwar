# frozen_string_literal: true

def admin_login(admin)
  visit new_admin_session_path
  fill_in 'Email', with: admin.email
  fill_in 'Password', with: 'changeme'
  click_button 'Login'
  expect(page).to have_css('div.flash', text: 'Signed in successfully')
end
