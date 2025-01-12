require "rails_helper"

describe "Residence", :with_frozen_time do
  let(:officer) { create(:poll_officer) }

  before { create(:geozone, :with_local_census_record) }

  describe "Officers without assignments" do
    scenario "Can not access residence verification" do
      login_as(officer.user)
      visit officing_root_path

      expect(page).not_to have_link("Validate document")
      expect(page).to have_content("You don't have officing shifts today")

      create(:poll_officer_assignment, officer: officer, date: 1.day.from_now)

      visit new_officing_residence_path

      expect(page).to have_content("You don't have officing shifts today")
    end
  end

  describe "Assigned officers" do
    before do
      create(:poll_officer_assignment, officer: officer)
      login_through_form_as_officer(officer.user)
      visit officing_root_path
    end

    scenario "Verify voter" do
      within("#side_menu") do
        click_link "Validate document"
      end

      select "TC Kimlik No", from: "residence_document_type"
      fill_in "residence_document_number", with: "12345678Z"
      fill_in "residence_phone_number", with: "905555555555"

      click_button "Validate document"

      expect(page).to have_content "Document verified with Census"
    end

    scenario "Error on verify" do
      within("#side_menu") do
        click_link "Validate document"
      end

      within("#new_residence") do
        click_button "Validate document"
      end

      expect(page).to have_content(/\d errors? prevented the verification of this document/)
    end

    scenario "Error on Census (document number)" do
      initial_failed_census_calls_count = officer.failed_census_calls_count
      within("#side_menu") do
        click_link "Validate document"
      end

      select "TC Kimlik No", from: "residence_document_type"
      fill_in "residence_document_number", with: "9999999A"
      fill_in "residence_phone_number", with: "905555555555"

      click_button "Validate document"

      expect(page).to have_content "The Census was unable to verify this document"

      officer.reload
      fcc = FailedCensusCall.last
      expect(fcc).to be
      expect(fcc.poll_officer).to eq(officer)
      expect(officer.failed_census_calls.last).to eq(fcc)
      expect(officer.failed_census_calls_count).to eq(initial_failed_census_calls_count + 1)
    end

    scenario "Error on Census (phone number)" do
      within("#side_menu") do
        click_link "Validate document"
      end

      select "TC Kimlik No", from: "residence_document_type"
      fill_in "residence_document_number", with: "12345678Z"
      fill_in "residence_phone_number", with: "906666666666"

      click_button "Validate document"

      expect(page).to have_content "The Census was unable to verify this document"
    end
  end

  scenario "Verify booth" do
    booth = create(:poll_booth)
    poll = create(:poll)

    create(:poll_officer_assignment, officer: officer, poll: poll, booth: booth)
    create(:poll_shift, officer: officer, booth: booth, date: Date.current)

    login_as(officer.user)

    visit new_officing_residence_path
    within("#officing-booth") do
      expect(page).to have_content "You are officing the booth located at #{booth.location}."
    end

    officing_verify_residence

    expect(page).to have_content poll.name
    click_button "Confirm vote"

    expect(page).to have_content "Vote introduced!"
  end
end
