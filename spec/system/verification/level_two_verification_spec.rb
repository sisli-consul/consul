require "rails_helper"

describe "Level two verification" do
  before { create(:geozone, :with_local_census_record) }

  scenario "Verification with residency and sms" do
    create(:geozone)
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    verify_residence

    click_button "Send"

    expect(page).to have_content "Security code confirmation"

    user = user.reload
    fill_in "sms_confirmation_code", with: user.sms_confirmation_code
    click_button "Send"

    expect(page).to have_content "Code correct"
  end

  context "In Spanish, with no fallbacks" do
    before do
      skip unless I18n.available_locales.include?(:es)
      allow(I18n.fallbacks).to receive(:[]).and_return([:es])
    end

    scenario "Works normally" do
      user = create(:user)
      login_as(user)

      visit verification_path(locale: :es)
      verify_residence
    end
  end
end
