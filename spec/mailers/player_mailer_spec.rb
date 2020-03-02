# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerMailer, type: :mailer do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player) { build_stubbed(:player, confirmation_token: 'xxx') }

  describe '#confirmation_email' do
    let(:mail) { PlayerMailer.with(player: player).confirmation_email }

    it 'renders the headers' do
      expect(mail.subject).to eq('Nautical War Signup')
      expect(mail.to).to eq([player.email])
      expect(mail.from).to eq(['support@nauticalwar.com'])
    end

    it 'renders the body' do
      expected = "Welcome to Nautical War, #{player.name}"
      expect(mail.body.encoded).to match(expected)
      expected = 'Please complete your signup by confirming your email address using the link below:'
      expect(mail.body.encoded).to match(expected)
      expected = "http://localhost:3000/confirm/#{player.confirmation_token}"
      expect(mail.body.encoded).to match(expected)
    end
  end

  describe '#reset_email' do
    let(:mail) { PlayerMailer.with(player: player).reset_email }

    before do
      # player.reset_password_token
      player.password_token = Player.generate_unique_secure_token
      player.password_token_expire = Time.zone.now + 1.hour
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Nautical War Password Reset')
      expect(mail.to).to eq([player.email])
      expect(mail.from).to eq(['support@nauticalwar.com'])
    end

    it 'renders the body' do
      expected = "Dear #{player.name},"
      expect(mail.body.encoded).to match(expected)
      expected = 'You may click here to reset your Nautical War account password:'
      expect(mail.body.encoded).to match(expected)
      expected = "http://localhost:3000/reset/#{player.password_token}"
      expect(mail.body.encoded).to match(expected)
    end
  end

  describe '#reset_complete_email' do
    let(:mail) { PlayerMailer.with(player: player).reset_complete_email }

    before do
      # player.reset_password_token
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Nautical War Password Reset Complete')
      expect(mail.to).to eq([player.email])
      expect(mail.from).to eq(['support@nauticalwar.com'])
    end

    it 'renders the body' do
      expected = "Dear #{player.name},"
      expect(mail.body.encoded).to match(expected)
      expected = 'Your Nautical War account password has been reset.'
      expect(mail.body.encoded).to match(expected)
      expected = 'http://localhost:3000/'
      expect(mail.body.encoded).to match(expected)
    end
  end
end
