require "rails_helper"

RSpec.feature 'Dashboard', type: :feature do
  let(:admin) { create(:player, :admin) }

  scenario 'Admin can login', js: true do
    admin_login(admin)
    visit admin_root_path
    expect(page).to have_text('Dashboard')
  end
end