class AdminAdapter < ActiveAdmin::AuthorizationAdapter
  def authorized?(action, subject = nil)
    !user.nil? && user.admin?
  end
end