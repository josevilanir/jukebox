class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :ensure_current_user
  helper_method :current_user, :show_name_modal?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def ensure_current_user
    return if current_user

    user = User.create!(name: "Guest-#{SecureRandom.hex(3)}", name_set: false)
    session[:user_id] = user.id
    @current_user = user
  end

  def show_name_modal?
    current_user.present? && !current_user.name_set?
  end
end
