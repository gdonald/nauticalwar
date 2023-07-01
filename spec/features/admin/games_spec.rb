# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Games' do
  let(:admin) { create(:player, :admin) }
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:game) do
    create(:game, player1: player_one, player2: player_two,
                  turn: player_one)
  end

  before { game }

  it 'Can visit games index', js: true do
    admin_login(admin)
    visit admin_games_path
    expect(page).to have_css('h2', text: 'Games')
    within('table#index_table_games tbody tr') do
      expect(page).to have_css('td', text: player_one.name)
      expect(page).to have_css('td', text: player_two.name)
      expect(page).to have_css('td', text: '86400')
    end
  end

  it 'Can edit game', js: true do
    admin_login(admin)
    visit admin_games_path
    within('table#index_table_games tbody tr') do
      click_link('Edit')
    end

    click_button 'Update Game'
    expect(page).to have_css('div.flash', text: 'Game was successfully updated')
  end
end
