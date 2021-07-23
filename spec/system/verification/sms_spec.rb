require "rails_helper"

describe "SMS Verification" do
  let(:user) { create(:user, residence_verified_at: Time.current, sms_confirmation_code: "1234") }
  let(:unverified) { create(:user) }

  before { login_as user }

  scenario "Verify" do
    visit new_sms_path

    click_button "Send"

    expect(page).to have_content "Security code confirmation"

    fill_in "sms_confirmation_code", with: "1234"
    click_button "Send"

    expect(page).to have_content "Code correct"
  end

  scenario "Errors on verification code" do
    visit new_sms_path

    click_button "Send"

    expect(page).to have_content "Security code confirmation"

    fill_in "sms_confirmation_code", with: "1235"
    click_button "Send"

    expect(page).to have_content "Incorrect confirmation code"
  end

  scenario "Deny access unless residency verified" do
    login_as(unverified)

    visit new_sms_path

    expect(page).to have_content "You have not yet confirmed your residency"
    expect(page).to have_current_path(new_residence_path)
  end

  scenario "5 tries allowed" do
    visit new_sms_path

    5.times do
      expect(page).to have_content "Send confirmation code"
      click_button "Send"

      expect(page).to have_content "Security code confirmation"
      click_link "Click here to send it again"
    end

    expect(page).to have_content "You have reached the maximum number of attempts. Please try again later."
    expect(page).to have_current_path(account_path)

    visit new_sms_path
    expect(page).to have_content "You have reached the maximum number of attempts. Please try again later."
    expect(page).to have_current_path(account_path)
  end
end
