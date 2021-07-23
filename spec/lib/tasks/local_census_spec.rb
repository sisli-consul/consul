require "rails_helper"

include ImportedCensusMock

describe "rake local_census:update" do
  let(:run_rake_task) { Rake.application.invoke_task("local_census:update") }

  before do
    Rake::Task["local_census:update"].reenable
    create(:geozone, name: "neighborhood")
  end

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
