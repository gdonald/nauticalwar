# frozen_string_literal: true

class HomeController < ApplicationController
  def index; end

  def android
    render layout: nil
  end
end
