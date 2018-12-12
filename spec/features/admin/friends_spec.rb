# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Friends', type: :feature do # rubocop:disable Metrics/BlockLength
  let(:admin) { create(:player, :admin) }
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let!(:friend) do
    create(:friend, player_1: player_1, player_2: player_2)
  end

  scenario 'Can visit friends index', js: true do
    admin_login(admin)
    visit admin_friends_path
    expect(page).to have_css('h2', text: 'Friends')
    within('table#index_table_friends tbody tr') do
      expect(page).to have_css('td', text: player_1.name)
      expect(page).to have_css('td', text: player_2.name)
      expect(page).to have_css('a', text: 'Delete')
    end
  end

  scenario 'Can delete friends', js: true do
    admin_login(admin)
    visit admin_friends_path
    within('table#index_table_friends tbody tr') do
      accept_confirm do
        click_link('Delete')
      end
    end

    expect(page).to have_css('span', text: 'There are no Friends yet.')
  end
end
