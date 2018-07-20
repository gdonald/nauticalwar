class Api::LayoutsController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: [:create]
  
  def create
    binding.pry
    @layout = Layout.create()
  end

  def show
  end
end
