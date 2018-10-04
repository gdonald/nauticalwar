# frozen_string_literal: true

class Api::EnemiesController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create; end
end
