# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Games' do
  let(:admin) { create(:player, :admin) }
  let(:player1) { create(:player, :confirmed) }
  let(:player2) { create(:player, :confirmed) }
  let(:game) do
    create(:game, player1:, player2:,
                  turn: player1)
  end

  before { game }

  it 'Can visit games index', js: true do
    admin_login(admin)
    visit admin_games_path
    expect(page).to have_css('h2', text: 'Games')
    within('table#index_table_games tbody tr') do
      expect(page).to have_css('td', text: player1.name)
      expect(page).to have_css('td', text: player2.name)
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
