require "rails_helper"

describe "Level three verification" do
  before { create(:geozone, :with_local_census_record) }

  scenario "Verification with residency and verified sms" do
    user = create(:user)

    verified_user = create(:verified_user,
                           document_number: "12345678Z",
                           document_type:   "1",
                           phone:           "611111111")

    login_as(user)

    visit account_path
    click_link "Verify my account"

    verify_residence

    within("#verified_user_#{verified_user.id}_phone") do
      click_button "Send code"
    end

    expect(page).to have_content "Security code confirmation"

    user = user.reload
    fill_in "sms_confirmation_code", with: user.sms_confirmation_code
    click_button "Send"

    expect(page).to have_content "Code correct. Your account is now verified"

    expect(page).not_to have_link "Verify my account"
    expect(page).to have_content "Account verified"
  end

  scenario "Verification with residency and verified email" do
    user = create(:user)

    verified_user = create(:verified_user,
                           document_number: "12345678Z",
                           document_type:   "1",
                           email:           "rock@example.com")

    login_as(user)

    visit account_path
    click_link "Verify my account"

    verify_residence

    within("#verified_user_#{verified_user.id}_email") do
      click_button "Send code"
    end

    expect(page).to have_content "We have sent a confirmation email to your account: rock@example.com"

    sent_token = /.*email_verification_token=(.*)".*/.match(ActionMailer::Base.deliveries.last.body.to_s)[1]
    visit email_path(email_verification_token: sent_token)

    expect(page).to have_content "You are a verified user"

    expect(page).not_to have_link "Verify my account"
    expect(page).to have_content "Account verified"
  end
end
