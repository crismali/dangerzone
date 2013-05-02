class SessionsController < ApplicationController

  def create
    @user = User.find_by_email(params[:email].downcase) if params[:email]
    if @user && @user.authenticate(params[:password]) && @user.confirmed
      @user.sign_in_ip = request.remote_ip
      @user.sign_in_count = @user.sign_in_count + 1
      if params[:remember_me] == '1'
        @user.remember_token = SecureRandom.urlsafe_base64
        cookies.permanent[:remember_token] = @user.remember_token
      else
        session[:user_id] = @user.id
      end
      @user.save
      redirect_to root_url, :notice => "Sign-in successful."
    else
      redirect_to sign_in_url, :notice => "Sign-in unsuccessful."
    end
  end

  def omniauth
    # fb and twitter authentification stuff go here
    # auth = request.env["omniauth.auth"]
  end

  def destroy
    cookies.delete(:remember_token)
    reset_session
    redirect_to sign_in_url, :notice => "Sign-out successful."
  end

  def new
  end

end