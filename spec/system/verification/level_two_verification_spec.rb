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

      select "DNI", from: "residence_document_type"
      fill_in "residence_document_number", with: "12345678Z"
      fill_in "residence_phone_number", with: "555555555"
      check "residence_terms_of_service"

      click_button "new_residence_submit"
      expect(page).to have_content I18n.t("verification.residence.create.flash.success")
    end
  end
end
