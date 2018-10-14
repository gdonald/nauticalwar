# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :authenticate_player!

  def index; end

  def android
    render layout: nil
  end
end
