require 'spec_helper'

describe CreateAccountsController do

  describe '#create' do

    before(:each) { ActionMailer::Base.deliveries = []}

    describe 'when successful' do

      before(:each) { post :create, params }
      let(:params) { { user: FactoryGirl.attributes_for(:user) } }

      it "assigns a user with the values in params" do
        expect(assigns(:user)).to eq(User.first)
      end

      it "sets their remember token" do
        expect(assigns(:user).remember_token).to_not be_nil
      end

      it "sends them a confirmation email" do
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it "saves the user" do
        expect(assigns(:user)).to_not be_new_record
      end

      it "redirect them to check_your_email" do
        expect(response).to redirect_to :check_your_email
      end
    end

    describe 'when unsuccessful' do

      let(:bad_params) { {:user => { email: 'x' }}}
      before(:each) { post :create, bad_params }

      it "redirects them to the sign up page" do
        expect(response).to redirect_to :sign_up
      end

      it "does not persist @user" do
        expect(assigns(:user)).to be_new_record
      end

      it "does not send them an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe '#new' do

    it "renders the new template" do
      get :new
      expect(response).to render_template :new
    end

  end

  describe '#resend_confirmation_email' do

    before(:each) { ActionMailer::Base.deliveries = []}
    let(:user){ FactoryGirl.create(:user) }

    it "redirects to the check_your_email page" do
      put :resend_confirmation_email, email: 'pun@example.com'
      expect(response).to redirect_to :check_your_email
    end

    describe "when user is not confirmed and has valid email" do

      it "sends a confirmation email" do
        put :resend_confirmation_email, email: user.email
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it "updates the user's reset password credentials" do
        old_token = user.reset_password_token
        old_time = user.reset_password_sent_at
        put :resend_confirmation_email, email: 'pun@example.com'
        expect(User.first.reset_password_token).to_not eq(old_token)
        expect(User.first.reset_password_sent_at).to_not eq(old_time)
      end
    end

    describe "when user is already confirmed" do
      let(:confirmed_user) { FactoryGirl.create(:confirmed_user) }
      before { put :resend_confirmation_email, email: 'pun_2@example.com' }

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it "does not update their reset password credentials" do
        user.should_not_receive :update_reset_password_credentials
        put :resend_confirmation_email, email: 'pun_2@example.com'
      end
    end

    describe "when email in params does not belong to any user" do

      it "does not send an email" do
        put :resend_confirmation_email, email: 'notthere@example.com'
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it "does not update their reset password credentials" do
        user.should_not_receive :update_reset_password_credentials
        put :resend_confirmation_email, email: 'notthere@example.com'
      end
    end
  end

  describe "#confirm" do

    let(:user){ FactoryGirl.create(:user) }
    before { user.update_reset_password_credentials }

    context "user has proper reset password credentials" do

      before {get :confirm, id: user.id, reset_password_token: user.reset_password_token}

      it "redirects to the root_url" do
        expect(response).to redirect_to root_url
      end

      it "confirms the user" do
        expect(User.first.confirmed).to be_true
      end

      it "puts the user's id in the session hash" do
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "user does not have right token" do
      before { get :confirm, id: user.id, reset_password_token: 'wrong'}

      it "redirects them to the sign up page" do
        expect(response).to redirect_to :sign_up
      end

      it "does not confirm the user" do
        expect(User.first.confirmed).to be_false
      end

      it "does not set the session hash to the user's id" do
        expect(session[:user_id]).to be_nil
      end
    end

    context "user is trying to confirm after more than an hour" do
      before do
        user.reset_password_sent_at = Time.now - 2.days
        user.save
        get :confirm, id: user.id, reset_password_token: user.reset_password_token
      end

      it "redirects them to the sign up page" do
        expect(response).to redirect_to :sign_up
      end

      it "does not confirm the user" do
        expect(User.first.confirmed).to be_false
      end

      it "does not set the session hash to the user's id" do
        expect(session[:user_id]).to be_nil
      end
    end
  end

end