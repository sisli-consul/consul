require "rails_helper"

describe Verification::Residence do
  let(:residence) { build(:verification_residence, document_number: "12345678Z") }

  before { create(:geozone, :with_local_census_record) }

  describe "validations" do
    it "is valid" do
      expect(residence).to be_valid
    end

    it "is not valid without a document number" do
      residence.document_number = nil

      expect(residence).not_to be_valid
    end

    it "is not valid without a phone number" do
      residence.phone_number = nil

      expect(residence).not_to be_valid
    end

    it "validates uniquness of document_number" do
      user = create(:user)
      residence.user = user
      residence.save!

      build(:verification_residence)

      residence.valid?
      expect(residence.errors[:document_number]).to include("has already been taken")
    end

    it "validates census terms" do
      residence.terms_of_service = nil
      expect(residence).not_to be_valid
    end
  end

  describe "new" do
    it "upcases document number" do
      residence = Verification::Residence.new(document_number: "x1234567z")
      expect(residence.document_number).to eq("X1234567Z")
    end

    it "removes all characters except numbers and letters" do
      residence = Verification::Residence.new(document_number: " 12.345.678 - B")
      expect(residence.document_number).to eq("12345678B")
    end
  end

  describe "save" do
    it "stores document number, document type, geozone, phone_number and gender" do
      user = create(:user)
      residence.user = user
      residence.save!

      user.reload
      expect(user.document_number).to eq("12345678Z")
      expect(user.document_type).to eq("1")
      expect(user.unconfirmed_phone).to eq("5555555555")
      expect(user.gender).to eq("male")
      expect(user.geozone).to eq(Geozone.first)
    end
  end

  describe "tries" do
    it "increases tries after a call to the Census" do
      residence.phone_number = "6666666666"
      residence.valid?
      expect(residence.user.lock.tries).to eq(1)
    end

    it "does not increase tries after a validation error" do
      residence.phone_number = ""
      residence.valid?
      expect(residence.user.lock).to be nil
    end
  end

  describe "Failed census call" do
    it "stores failed census API calls" do
      residence = build(:verification_residence, :invalid, document_number: "12345678Z")
      residence.save

      expect(FailedCensusCall.count).to eq(1)
      expect(FailedCensusCall.first).to have_attributes(
        user_id:         residence.user.id,
        document_number: "12345678Z",
        document_type:   "1",
        phone_number:    "6666666666"
      )
    end
  end
end
