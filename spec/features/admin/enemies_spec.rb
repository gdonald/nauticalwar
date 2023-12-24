# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enemies' do
  let(:admin) { create(:player, :admin) }
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:enemy) do
    create(:enemy, player1: player_one, player2: player_two)
  end

  before { enemy }

  it 'Can visit enemies index', :js do
    admin_login(admin)
    visit admin_enemies_path
    expect(page).to have_css('h2', text: 'Enemies')
    within('table#index_table_enemies tbody tr') do
      expect(page).to have_css('td', text: player_one.name)
      expect(page).to have_css('td', text: player_two.name)
      expect(page).to have_css('a', text: 'Delete')
    end
  end

  it 'Can delete enemies', :js do
    admin_login(admin)
    visit admin_enemies_path
    within('table#index_table_enemies tbody tr') do
      accept_confirm do
        click_link('Delete')
      end
    end

    expect(page).to have_css('span', text: 'There are no Enemies yet.')
  end
end
