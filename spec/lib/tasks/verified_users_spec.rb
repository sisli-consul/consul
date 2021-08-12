require "rails_helper"

include ImportedCensusMock

describe "rake verified_users:update" do
  let(:run_rake_task) { Rake.application.invoke_task("verified_users:update") }
  let(:geozone) { Geozone.first }

  before do
    Rake::Task["verified_users:update"].reenable
    create(:geozone, name: "neighborhood")
  end

  describe "local census records" do
    it "does import the data from databases" do
      mock_valid_imported_census_records(ImportedUserFirst)
      mock_empty_imported_census_records(ImportedUserSecond)
      mock_empty_imported_census_records(ImportedUserThird)

      expect(LocalCensusRecord.all).to be_empty

      run_rake_task

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "VALID - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "905555555555"
      expect(local_census_record.gender).to eq "ERKEK"
      expect(local_census_record.neighborhood).to eq "neighborhood"
    end

    it "does update the record values if the document ID exists" do
      mock_valid_imported_census_records(ImportedUserFirst)
      mock_empty_imported_census_records(ImportedUserSecond)
      mock_empty_imported_census_records(ImportedUserThird)

      create(:local_census_record, name: "EXISTING - USER",
             document_number: "30905178092",
             phone_number: "906666666666",
             gender: "KADIN",
             neighborhood: "Madrid")

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "EXISTING - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "906666666666"
      expect(local_census_record.gender).to eq "KADIN"
      expect(local_census_record.neighborhood).to eq "Madrid"

      run_rake_task

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "VALID - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "905555555555"
      expect(local_census_record.gender).to eq "ERKEK"
      expect(local_census_record.neighborhood).to eq "neighborhood"
    end

    it "skip data from second database if it was imported from first database" do
      mock_valid_imported_census_records(ImportedUserFirst)
      mock_valid_repeated_imported_census_records(ImportedUserSecond)
      mock_empty_imported_census_records(ImportedUserThird)

      expect(LocalCensusRecord.all).to be_empty

      run_rake_task

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "VALID - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "905555555555"
      expect(local_census_record.gender).to eq "ERKEK"
      expect(local_census_record.neighborhood).to eq "neighborhood"
    end

    it "skip data from third database if it was imported from second database" do
      mock_empty_imported_census_records(ImportedUserFirst)
      mock_valid_imported_census_records(ImportedUserSecond)
      mock_valid_repeated_imported_census_records(ImportedUserThird)

      expect(LocalCensusRecord.all).to be_empty

      run_rake_task

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "VALID - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "905555555555"
      expect(local_census_record.gender).to eq "ERKEK"
      expect(local_census_record.neighborhood).to eq "neighborhood"
    end

    it "does delete old records" do
      mock_empty_imported_census_records(ImportedUserFirst)
      mock_empty_imported_census_records(ImportedUserSecond)
      mock_empty_imported_census_records(ImportedUserThird)

      create(:local_census_record, name: "OLD - USER",
             document_number: "98765432100",
             phone_number: "905666666666",
             gender: "ERKEK",
             neighborhood: "neighborhood",
             updated_at: 1.day.ago)

      expect(LocalCensusRecord.count).to be 1

      run_rake_task

      expect(LocalCensusRecord.all).to be_empty
    end

    it "does not duplicate when importing data from databases" do
      mock_valid_imported_census_records(ImportedUserFirst)
      mock_valid_imported_census_records(ImportedUserSecond)
      mock_valid_imported_census_records(ImportedUserThird)

      expect(LocalCensusRecord.all).to be_empty

      run_rake_task

      expect(LocalCensusRecord.count).to be 1
      local_census_record = LocalCensusRecord.first
      expect(local_census_record.name).to eq "VALID - USER"
      expect(local_census_record.document_number).to eq "30905178092"
      expect(local_census_record.phone_number).to eq "905555555555"
      expect(local_census_record.gender).to eq "ERKEK"
      expect(local_census_record.neighborhood).to eq "neighborhood"
    end

    it "does not import invalid data from databases" do
      mock_invalid_imported_census_records(ImportedUserFirst, "id_number")
      mock_invalid_imported_census_records(ImportedUserSecond, "algorithm_id_number", "phone_number")
      mock_invalid_imported_census_records(ImportedUserThird, "neighborhood")

      expect(LocalCensusRecord.all).to be_empty

      run_rake_task

      expect(LocalCensusRecord.all).to be_empty
    end
  end

  describe "verified users" do
    before do
      mock_valid_imported_census_records(ImportedUserFirst)
      mock_empty_imported_census_records(ImportedUserSecond)
      mock_empty_imported_census_records(ImportedUserThird)
    end

    it "are not unverified if they are in the local census records" do
      user = create(:user, :level_two, :level_three, document_number: "30905178092",
                        phone_number: "905555555555", geozone_id: geozone.id)

      expect(user.level_three_verified?).to be true

      run_rake_task

      expect(user.reload.level_three_verified?).to be true
    end

    it "are unverified if the document number has changed in the local census records" do
      user = create(:user, :level_two, :level_three, document_number: "other document number",
                        phone_number: "905555555555", geozone_id: geozone.id)

      expect(user.level_three_verified?).to be true

      run_rake_task

      expect(user.reload.level_three_verified?).to be false
    end

    it "are unverified if the telephone number has changed in the local census records" do
      user = create(:user, :level_two, :level_three, document_number: "30905178092",
                        phone_number: "other phone number", geozone_id: geozone.id)

      expect(user.level_three_verified?).to be true

      run_rake_task

      expect(user.reload.level_three_verified?).to be false
    end

    it "are unverified the geozone has changed in the local census records" do
      other_geozone = create :geozone
      user = create(:user, :level_two, :level_three, document_number: "old document number",
                        phone_number: "905555555555", geozone_id: other_geozone.id)

      expect(user.level_three_verified?).to be true

      run_rake_task

      expect(user.reload.level_three_verified?).to be false
    end

    it "does change many attributes" do
      outdated = create(:user, :level_two, :level_three, document_number: "old document number")
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
end
