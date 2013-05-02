class ResetPasswordsController < ApplicationController

  def send_reset_password
    @user = User.find_by_email(params[:email].downcase)
    if @user
      @user.update_reset_password_credentials
      DangerzoneMailer.reset_password_email(@user).deliver
      redirect_to forgot_password_url, notice: "Reset password email successfully sent."
    else
      redirect_to forgot_password_url, notice: "Reset password email failed to send."
    end
  end

  def reset_password_form
    @user = User.find_by_id(params[:id])
    if @user && (Time.now - @user.reset_password_sent_at) < 60.minutes && @user.reset_password_token == params[:reset_password_token]
      session[:reset_password_user_id] = @user.id
    else
      redirect_to forgot_password_url, notice: "There was a problem, try having the email resent to you."
    end
  end

  def update_password
    @user = User.find_by_id(session[:reset_password_user_id])
    if @user && (Time.now - @user.reset_password_sent_at) < 60.minutes
      @user.password = params[:password]
      @user.password_confirmation = params[:password_confirmation]
      if @user.save
        reset_session
        session[:user_id] = @user.id
        redirect_to root_url, notice: "Password successfully updated."
      else
        redirect_to reset_password_form_url(@user.id, @user.reset_password_token), notice: "Update password unsuccessful: password confirmation did not match password."
      end
    else
      redirect_to send_reset_password_url, notice: "Update password unsuccessful."
    end
  end

  def new
  end

end