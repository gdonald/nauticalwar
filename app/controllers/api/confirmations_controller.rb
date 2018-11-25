# frozen_string_literal: true

class Api::ConfirmationsController < Devise::ConfirmationsController # rubocop:disable Style/ClassAndModuleChildren, Metrics/LineLength
  def show # rubocop:disable Metrics/AbcSize
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      redirect_to android_path
    else
      respond_with_navigational(resource.errors,
                                status: :unprocessable_entity) { render :new }
    end
  end
end
