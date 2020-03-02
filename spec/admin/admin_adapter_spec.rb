# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminAdapter, type: :model do
  describe '#authorized?' do
    let(:application) { ActiveAdmin.application }
    let(:namespace) { application.namespaces.first }
    let(:resources) { namespace.resources }
    let(:klass) { Game }
    let(:resource) { resources[klass] }
    let(:adapter) { AdminAdapter.new resource, user }

    describe 'as user' do
      let(:user) { build_stubbed(:player) }

      it 'returns false' do
        expect(adapter.authorized?(user)).to be_falsey
      end
    end

    describe 'as admin' do
      let(:user) { build_stubbed(:player, :admin) }

      it 'returns true' do
        expect(adapter.authorized?(user)).to be_truthy
      end
    end
  end
end
