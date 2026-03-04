class UsersController < ApplicationController
  def update
    if current_user.update(name: params[:name], name_set: true)
      redirect_back_or_to root_path, notice: "Nome salvo!"
    else
      redirect_back_or_to root_path, alert: current_user.errors.full_messages.to_sentence
    end
  end
end
