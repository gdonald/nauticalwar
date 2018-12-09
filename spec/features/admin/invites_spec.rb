require "rails_helper"

RSpec.feature 'Invites', type: :feature do
  let(:admin) { create(:player, :admin) }
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let!(:invite) { create(:invite, player_1: player_1, player_2: player_2) }

  scenario 'Can visit invites index', js: true do
    admin_login(admin)
    visit admin_invites_path
    expect(page).to have_css('h2', text: 'Invites')
    within('table#index_table_invites tbody tr') do
      expect(page).to have_css('td', text: player_1.name)
      expect(page).to have_css('td', text: player_2.name)
      expect(page).to have_css('td', text: '86400')
    end
  end

  scenario 'Can edit invite', js: true do
    admin_login(admin)
    visit admin_invites_path
    within('table#index_table_invites tbody tr') do
      click_link('Edit')
    end

    click_button 'Update Invite'
    expect(page).to have_css('div.flash', text: 'Invite was successfully updated')
  end
end