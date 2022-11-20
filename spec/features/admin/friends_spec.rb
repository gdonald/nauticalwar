# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Friends' do
  let(:admin) { create(:player, :admin) }
  let(:player1) { create(:player, :confirmed) }
  let(:player2) { create(:player, :confirmed) }
  let(:friend) do
    create(:friend, player1:, player2:)
  end

  before { friend }

  it 'Can visit friends index', js: true do
    admin_login(admin)
    visit admin_friends_path
    expect(page).to have_css('h2', text: 'Friends')
    within('table#index_table_friends tbody tr') do
      expect(page).to have_css('td', text: player1.name)
      expect(page).to have_css('td', text: player2.name)
      expect(page).to have_css('a', text: 'Delete')
    end
  end

  it 'Can delete friends', js: true do
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
