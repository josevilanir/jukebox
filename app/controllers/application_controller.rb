class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :ensure_current_user
  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def ensure_current_user
    return if current_user

    user = User.create!(name: "Guest-#{SecureRandom.hex(3)}")
    session[:user_id] = user.id
    @current_user = user
  end
end
