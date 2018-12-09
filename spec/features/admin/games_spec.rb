require "rails_helper"

RSpec.feature 'Games', type: :feature do
  let(:admin) { create(:player, :admin) }
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let!(:game) { create(:game, player_1: player_1, player_2: player_2, turn: player_1) }

  scenario 'Can visit games index', js: true do
    admin_login(admin)
    visit admin_games_path
    expect(page).to have_css('h2', text: 'Games')
    within('table#index_table_games tbody tr') do
      expect(page).to have_css('td', text: player_1.name)
      expect(page).to have_css('td', text: player_2.name)
      expect(page).to have_css('td', text: '86400')
    end
  end

  scenario 'Can edit game', js: true do
    admin_login(admin)
    visit admin_games_path
    within('table#index_table_games tbody tr') do
      click_link('Edit')
    end

    click_button 'Update Game'
    expect(page).to have_css('div.flash', text: 'Game was successfully updated')
  end
end