# frozen_string_literal: true

def login(player)
  allow(request.env['warden']).to receive(:authenticate!) { player }
  allow(controller).to receive(:current_api_player) { player }
end
