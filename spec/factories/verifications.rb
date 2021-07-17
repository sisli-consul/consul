FactoryBot.define do
  factory :local_census_record, class: "LocalCensusRecord" do
    sequence(:document_number) { |n| "DOC_NUMBER#{n}" }
    document_type { 1 }
    phone_number { "5555555555" }
    gender { "Erkek" }
    neighborhood { "neighborhood" }
  end
  factory :local_census_records_import, class: "LocalCensusRecords::Import" do
    file do
      path = %w[spec fixtures files local_census_records import valid.csv]
      Rack::Test::UploadedFile.new(Rails.root.join(*path))
    end
  end

  sequence(:document_number) { |n| "#{n.to_s.rjust(8, "0")}X" }

  factory :verification_residence, class: "Verification::Residence" do
    user
    document_number
    document_type    { "1" }
    phone_number     { "5555555555" }
    terms_of_service { "1" }

    trait :invalid do
      phone_number { "6666666666" }
    end
  end

  factory :failed_census_call do
    user
    document_number
    document_type { 1 }
    date_of_birth { Date.new(1900, 1, 1) }
    postal_code { "28000" }
  end

  factory :verification_sms, class: "Verification::Sms" do
  end

  factory :verification_letter, class: "Verification::Letter" do
    user
    email { "user@consul.dev" }
    password { "1234" }
    verification_code { "5555" }
  end

  factory :lock do
    user
    tries { 0 }
    locked_until { Time.current }
  end

  factory :verified_user do
    document_number
    document_type { "dni" }
  end

  factory :verification_document, class: "Verification::Management::Document" do
    document_number
    document_type { "1" }
    phone_number { "5555555555" }
  end
end
