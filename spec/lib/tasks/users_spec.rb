require "rails_helper"

describe "rake users:update_verified" do
  let(:run_rake_task) { Rake.application.invoke_task("users:update_verified") }

  before do
    Rake::Task["users:update_verified"].reenable
    create(:geozone, :with_local_census_record)
  end

  it "does unverify users that are not in the local census records" do
    verified = create(:user, :level_two, :level_three, document_number: "12345678Z")
    outdated = create(:user, :level_two, :level_three, document_number: "987654321")

    expect(verified.level_three_verified?).to be true
    expect(outdated.level_three_verified?).to be true

    run_rake_task

    expect(verified.reload.level_three_verified?).to be true
    expect(outdated.reload.level_three_verified?).to be false
  end

  it "does change many attributes" do
    outdated = create(:user, :level_two, :level_three, document_number: "987654321")
    last_updated = outdated.updated_at

    expect(outdated.name).not_to be nil
    expect(outdated.gender).not_to be nil
    expect(outdated.sms_confirmation_code).not_to be nil
    expect(outdated.unconfirmed_phone).not_to be nil
    expect(outdated.confirmed_phone).not_to be nil
    expect(outdated.phone_number).not_to be nil
    expect(outdated.document_number).not_to be nil
    expect(outdated.document_type).not_to be nil
    expect(outdated.geozone_id).not_to be nil
    expect(outdated.residence_verified_at).not_to be nil
    expect(outdated.level_two_verified_at).not_to be nil
    expect(outdated.verified_at).not_to be nil

    run_rake_task

    outdated.reload
    expect(outdated.updated_at).not_to eq last_updated
    expect(outdated.gender).to be nil
    expect(outdated.sms_confirmation_code).to be nil
    expect(outdated.unconfirmed_phone).to be nil
    expect(outdated.confirmed_phone).to be nil
    expect(outdated.phone_number).to be nil
    expect(outdated.document_number).to be nil
    expect(outdated.document_type).to be nil
    expect(outdated.geozone_id).to be nil
    expect(outdated.residence_verified_at).to be nil
    expect(outdated.level_two_verified_at).to be nil
    expect(outdated.verified_at).to be nil
  end

  it "does not change not verified users" do
    last_updated = create(:user).updated_at

    run_rake_task

    expect(User.last.updated_at).not_to be > last_updated
  end

  it "does not change special users" do
    administrator = create(:administrator).user
    moderator = create(:moderator).user
    valuator = create(:valuator).user
    official = create(:user, official_level: 1)
    manager = create(:manager).user
    sdg_manager = create(:sdg_manager).user
    poll_officer = create(:poll_officer).user
    organization = create(:organization).user

    administrator_last_updated = administrator.updated_at
    moderator_last_updated = moderator.updated_at
    valuator_last_updated = valuator.updated_at
    official_last_updated = official.updated_at
    manager_last_updated = manager.updated_at
    sdg_manager_last_updated = sdg_manager.updated_at
    poll_officer_last_updated = poll_officer.updated_at
    organization_last_updated = organization.updated_at

    run_rake_task

    expect(administrator.reload.updated_at).not_to be > administrator_last_updated
    expect(moderator.reload.updated_at).not_to be > moderator_last_updated
    expect(valuator.reload.updated_at).not_to be > valuator_last_updated
    expect(official.reload.updated_at).not_to be > official_last_updated
    expect(manager.reload.updated_at).not_to be > manager_last_updated
    expect(sdg_manager.reload.updated_at).not_to be > sdg_manager_last_updated
    expect(poll_officer.reload.updated_at).not_to be > poll_officer_last_updated
    expect(organization.reload.updated_at).not_to be > organization_last_updated
  end
end
