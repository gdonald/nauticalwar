# frozen_string_literal: true

class AdminAdapter < ActiveAdmin::AuthorizationAdapter
  def authorized?(_action, _subject = nil)
    !user.nil? && user.admin?
  end
end
