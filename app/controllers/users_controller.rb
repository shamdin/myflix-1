class UsersController < ApplicationController
  
  def new
    @user = User.new
  end
  
  def create
     @user = User.new(user_params)
    
    if @user.valid?
      charge = StripeWrapper::Charge.create(
        :amount => 999,
        :card => params[:stripeToken],
        :description => "Charge for MyFlix for #{@user.email}")
      if charge.successful?
        @user.save
        handle_invitation
        AppMailer.welcome_mail(@user).deliver
        flash[:success] = "Thank you for registering with MyFlix. Please sign in now."
        redirect_to login_path
      else
        flash[:error] = charge.error_message   
        render :new
      end
    else
      render :new
    end
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new_with_invitation_token
    invitation = Invitation.where(token: params[:token]).first
    if invitation
      @user = User.new(email: invitation.recipient_email)
      @invitation_token = invitation.token
      render :new
    else
      redirect_to expired_token_path
    end
  end


private
  def user_params
    params.require(:user).permit(:name, :password, :email)
  end
  
  def handle_invitation
    if params[:invitation_token].present?      
      invitation = Invitation.where(token: params[:invitation_token]).first    
      @user.follow(invitation.inviter)      
      invitation.inviter.follow(@user)
      invitation.update_column(:token, nil)
    end
  end
  
end