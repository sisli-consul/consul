class Verification::SmsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_resident!
  before_action :verify_verified!
  before_action :verify_lock, only: [:new, :create]

  skip_authorization_check

  def new
    @sms = Verification::Sms.new(user: current_user)
  end

  def create
    @sms = Verification::Sms.new(user: current_user)
    if @sms.save
      redirect_to edit_sms_path, notice: t("verification.sms.create.flash.success")
    else
      render :new
    end
  end

  def edit
    @sms = Verification::Sms.new
  end

  def update
    @sms = Verification::Sms.new(sms_params.merge(user: current_user))
    if @sms.verified?
      current_user.update!(confirmed_phone: current_user.unconfirmed_phone, verified_at: Time.current)
      ahoy.track(:level_2_user, user_id: current_user.id) rescue nil

      redirect_to_next_path
    else
      @error = t("verification.sms.update.error")
      render :edit
    end
  end

  private

    def sms_params
      params.require(:sms).permit(:confirmation_code)
    end

    def redirect_to_next_path
      current_user.reload
      if current_user.level_three_verified?
        redirect_to account_path, notice: t("verification.sms.update.flash.level_three.success")
      else
        redirect_to verified_user_path, notice: t("verification.residence.create.flash.success")
      end
    end
end
