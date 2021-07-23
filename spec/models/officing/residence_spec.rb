require "rails_helper"

describe Officing::Residence do
  let(:residence) { build(:officing_residence, document_number: "12345678Z") }

  before { create(:geozone, :with_local_census_record) }

  describe "validations" do
    it "is valid" do
      expect(residence).to be_valid
    end

    it "is not valid without a document number" do
      residence.document_number = nil
      expect(residence).not_to be_valid
    end

    it "is not valid without a document type" do
      residence.document_type = nil
      expect(residence).not_to be_valid
    end

    it "is not valid without a phone number" do
      residence.phone_number = nil
      expect(residence).not_to be_valid
    end

    describe "custom validations", :remote_census do
      let(:custom_residence) do
        build(:officing_residence, document_number: "12345678Z")
      end

      it "is not valid without a document number" do
        custom_residence.document_number = nil
        expect(custom_residence).not_to be_valid
      end

      it "is not valid without a document type" do
        custom_residence.document_type = nil
        expect(custom_residence).not_to be_valid
      end
    end
  end

  describe "new" do
    it "upcases document number" do
      residence = Officing::Residence.new(document_number: "x1234567z")
      expect(residence.document_number).to eq("X1234567Z")
    end

    it "removes all characters except numbers and letters" do
      residence = Officing::Residence.new(document_number: " 12.345.678 - B")
      expect(residence.document_number).to eq("12345678B")
    end
  end

  describe "save" do
    it "stores document number, document type, geozone and gender" do
      residence.save!
      user = residence.user

      expect(user.document_number).to eq("12345678Z")
      expect(user.document_type).to eq("1")
      expect(user.gender).to eq("male")
      expect(user.geozone).to eq(Geozone.first)
    end

    it "finds existing user and updates demographic information" do
      create(:geozone)
      create(:user, document_number: "12345678Z",
                    document_type: "1",
                    date_of_birth: Date.new(1981, 11, 30),
                    gender: "female",
                    geozone: Geozone.last)

      residence = build(:officing_residence,
                        document_number: "12345678Z",
                        document_type: "1")

      residence.save!
      user = residence.user

      expect(user.document_number).to eq("12345678Z")
      expect(user.document_type).to eq("1")
      expect(user.date_of_birth.year).to eq(1981)
      expect(user.date_of_birth.month).to eq(11)
      expect(user.date_of_birth.day).to eq(30)
      expect(user.gender).to eq("male")
      expect(user.geozone).to eq(Geozone.first)
    end

    it "makes half-verified users fully verified" do
      user = create(:user, residence_verified_at: Time.current, document_type: "1", document_number: "12345678Z")
      expect(user).to be_unverified
      residence = build(:officing_residence, document_number: "12345678Z")
      expect(residence).to be_valid
      expect(user.reload).to be_unverified
      residence.save!
      expect(user.reload).to be_level_three_verified
    end

    it "stores failed census calls" do
      residence = build(:officing_residence, :invalid, document_number: "12345678Z")
      residence.save

      expect(FailedCensusCall.count).to eq(1)
      expect(FailedCensusCall.first).to have_attributes(
        user_id:         residence.user.id,
        poll_officer_id: residence.officer.id,
        document_number: "12345678Z",
        document_type:   "1",
        date_of_birth: nil,
        postal_code: nil
      )
    end
  end
end
