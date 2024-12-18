module Dev
  class UsersController < ApplicationController
    include DevRouteProtection

    def index
      @users = User.all
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to dev_users_path, notice: "User created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def switch
      user = User.find(params[:id])
      session = user.sessions.create!
      cookies.signed[:session_token] = { value: session.token, httponly: true }
      redirect_to root_path, notice: "Switched to #{user.email_address}"
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
