require "rails_helper"

describe Verification::Sms do
  it "is valid" do
    sms = build(:verification_sms)
    expect(sms).to be_valid
  end
end
