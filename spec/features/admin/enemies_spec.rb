# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enemies' do
  let(:admin) { create(:player, :admin) }
  let(:player1) { create(:player, :confirmed) }
  let(:player2) { create(:player, :confirmed) }
  let(:enemy) do
    create(:enemy, player1:, player2:)
  end

  before { enemy }

  it 'Can visit enemies index', js: true do
    admin_login(admin)
    visit admin_enemies_path
    expect(page).to have_css('h2', text: 'Enemies')
    within('table#index_table_enemies tbody tr') do
      expect(page).to have_css('td', text: player1.name)
      expect(page).to have_css('td', text: player2.name)
      expect(page).to have_css('a', text: 'Delete')
    end
  end

  it 'Can delete enemies', js: true do
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
