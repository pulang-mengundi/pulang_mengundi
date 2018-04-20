class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    if current_admin
      @user = User.find(params[:user_id])
      @user.update(profile_params)
    else  
      @user = current_user
      if @user.update(profile_params)
        if params.dig(:user, :email).present? && (@user.email != params.dig(:user, :email))
          @user.unconfirmed_email = params.dig(:user, :email)
          if @user.save
            UserMailer.with(user_id: @user.id).confirmation_email.deliver_later
            flash[:success] = t('.check_email')
          else
            flash[:danger] = t('.invalid_email')
          end
        else
          flash[:success] = t('.success')
        end      
      else
        flash[:danger] = @user.errors.full_messages.join("; ")
      end
      redirect_back_or(edit_profiles_path)
    end
  end

  private
    def profile_params
      params.require(:user).permit(:phone_area_code, :phone_number, :email_public, :ic, :flagged)
    end
end