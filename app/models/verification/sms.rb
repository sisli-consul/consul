class Verification::Sms
  include ActiveModel::Model

  attr_accessor :user, :confirmation_code

  def save
    send_sms
    Lock.increase_tries(user)
  end

  def send_sms
    SMSApi.new.sms_deliver(user.unconfirmed_phone, user.sms_confirmation_code)
  end

  def verified?
    user.sms_confirmation_code == confirmation_code
  end
end
