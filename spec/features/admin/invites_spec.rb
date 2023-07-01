# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invites' do
  let(:admin) { create(:player, :admin) }
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:invite) { create(:invite, player1: player_one, player2: player_two) }

  before { invite }

  it 'Can visit invites index', js: true do
    admin_login(admin)
    visit admin_invites_path
    expect(page).to have_css('h2', text: 'Invites')
    within('table#index_table_invites tbody tr') do
      expect(page).to have_css('td', text: player_one.name)
      expect(page).to have_css('td', text: player_two.name)
      expect(page).to have_css('td', text: '86400')
    end
  end

  it 'Can edit invite', js: true do
    admin_login(admin)
    visit admin_invites_path
    within('table#index_table_invites tbody tr') do
      click_link('Edit')
    end

    click_button 'Update Invite'
    expect(page).to have_css('div.flash',
                             text: 'Invite was successfully updated')
  end
end
