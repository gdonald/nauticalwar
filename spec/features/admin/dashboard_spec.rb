# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:admin) { create(:player, :admin) }

  it 'Admin can login', :js do
    admin_login(admin)
    visit admin_root_path
    expect(page).to have_text('Dashboard')
  end
end
