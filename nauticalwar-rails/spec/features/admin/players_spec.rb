# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Players' do
  let(:admin) { create(:player, :admin) }

  it 'Can visit invites index', :js do
    admin_login(admin)
    visit admin_players_path
    expect(page).to have_css('h2', text: 'Players')
    within('table#index_table_players tbody tr') do
      expect(page).to have_css('td', text: admin.email)
      expect(page).to have_css('td', text: '1200')
    end
  end

  it 'Admin can edit player', :js do
    player = create(:player)

    admin_login(admin)
    visit admin_players_path

    within("table#index_table_players tbody tr#player_#{player.id}") do
      click_on('Edit')
    end

    within 'li#player_password_input' do
      fill_in 'Password', with: 'changeme'
    end

    fill_in 'Password confirmation', with: 'changeme'
    click_on 'Update Player'

    expect(page).to have_css('div.flash',
                             text: 'Player was successfully updated')
  end
end
