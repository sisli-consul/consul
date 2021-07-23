require "rails_helper"

describe "Tracking" do
  before { create(:geozone, :with_local_census_record) }

  context "Custom variable" do
    scenario "Usertype anonymous" do
      visit proposals_path

      expect(page.html).to include "anonymous"
    end

    scenario "Usertype level_1_user" do
      user = create(:user)
      login_as(user)

      visit proposals_path

      expect(page.html).to include "level_1_user"
    end

    scenario "Usertype level_3_user" do
      user = create(:user)
      login_as(user)

      visit account_path
      click_link "Verify my account"

      verify_residence

      click_button "Send"

      user = user.reload
      fill_in "sms_confirmation_code", with: user.sms_confirmation_code
      click_button "Send"

      expect(page.html).to include "level_3_user"
    end
  end

  context "Tracking events" do
    scenario "Verification: start census" do
      user = create(:user)
      login_as(user)

      visit account_path
      click_link "Verify my account"

      expect(page).to have_selector "[data-track-event-category='verification']", visible: :all
      expect(page).to have_selector "[data-track-event-action='start_census']", visible: :all
    end

    scenario "Verification: success census & start sms" do
      user = create(:user)
      login_as(user)

      visit account_path
      click_link "Verify my account"

      verify_residence

      click_button "Send"

      expect(page).to have_selector "[data-track-event-category='verification']", visible: :all
      expect(page).to have_selector "[data-track-event-action='start_sms']", visible: :all
    end

    scenario "Verification: success sms" do
      user = create(:user)
      login_as(user)

      visit account_path
      click_link "Verify my account"

      verify_residence

      click_button "Send"

      user = user.reload
      fill_in "sms_confirmation_code", with: user.sms_confirmation_code
      click_button "Send"

      expect(page).to have_selector "[data-track-event-category='verification']", visible: :all
      expect(page).to have_selector "[data-track-event-action='success_sms']", visible: :all
    end
  end
end
