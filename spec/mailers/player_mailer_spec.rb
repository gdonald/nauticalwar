# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerMailer, type: :mailer do
  let(:player) { create(:player) }
  let(:mail) { PlayerMailer.with(player: player).confirmation_email }

  describe '' do
    it 'renders the headers' do
      expect(mail.subject).to eq('Nautical War Signup')
      expect(mail.to).to eq([player.email])
      expect(mail.from).to eq(['support@nauticalwar.com'])
    end

    it 'renders the body' do
      expected = "Welcome to Nautical War, #{player.name}"
      expect(mail.body.encoded).to match(expected)
      expected = 'Click here to confirm your email:'
      expect(mail.body.encoded).to match(expected)
      expected = "http://localhost:3000/confirm/#{player.confirmation_token}"
      expect(mail.body.encoded).to match(expected)
    end
  end
end
