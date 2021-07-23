require "rails_helper"

describe "Residence" do
  before { create(:geozone, :with_local_census_record) }

  scenario "Verify resident" do
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    fill_in "residence_document_number", with: "12345678Z"
    select "DNI", from: "residence_document_type"
    fill_in "residence_phone_number", with: "5555555555"
    check "residence_terms_of_service"
    click_button "Verify residence"

    expect(page).to have_content "Residence verified"
  end

  scenario "When trying to verify a deregistered account old votes are reassigned" do
    erased_user = create(:user, document_number: "12345678Z", document_type: "1", erased_at: Time.current)
    vote = create(:vote, voter: erased_user)
    new_user = create(:user)

    login_as(new_user)

    visit account_path
    click_link "Verify my account"

    fill_in "residence_document_number", with: "12345678Z"
    select "DNI", from: "residence_document_type"
    fill_in "residence_phone_number", with: "5555555555"
    check "residence_terms_of_service"

    click_button "Verify residence"

    expect(page).to have_content "Residence verified"

    expect(vote.reload.voter).to eq(new_user)
    expect(erased_user.reload.document_number).to be_blank
    expect(new_user.reload.document_number).to eq("12345678Z")
  end

  scenario "Error on verify" do
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    click_button "Verify residence"

    expect(page).to have_content(/\d errors? prevented the verification of your residence/)
  end

  scenario "Error on census" do
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    fill_in "residence_document_number", with: "012345678"
    select "DNI", from: "residence_document_type"
    fill_in "residence_phone_number", with: "5555555555"
    check "residence_terms_of_service"

    click_button "Verify residence"

    expect(page).to have_content "The Census was unable to verify your information"
  end

  scenario "5 tries allowed" do
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    5.times do
      fill_in "residence_document_number", with: "012345678"
      select "DNI", from: "residence_document_type"
      fill_in "residence_phone_number", with: "5555555555"
      check "residence_terms_of_service"

      click_button "Verify residence"
      expect(page).to have_content "The Census was unable to verify your information"
    end

    click_button "Verify residence"
    expect(page).to have_content "You have reached the maximum number of attempts. Please try again later."
    expect(page).to have_current_path(account_path)

    visit new_residence_path
    expect(page).to have_content "You have reached the maximum number of attempts. Please try again later."
    expect(page).to have_current_path(account_path)
  end
end
