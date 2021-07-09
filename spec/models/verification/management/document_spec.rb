require "rails_helper"

describe Verification::Management::Document do
  let(:verification_document) { build(:verification_document, document_number: "12345678Z") }

  describe "validations" do
    it "is valid" do
      expect(verification_document).to be_valid
    end

    it "is not valid without a document number" do
      verification_document.document_number = nil
      expect(verification_document).not_to be_valid
    end

    it "is not valid without a document type" do
      verification_document.document_type = nil
      expect(verification_document).not_to be_valid
    end

    it "is not valid without a phone number" do
      verification_document.phone_number = nil
      expect(verification_document).not_to be_valid
    end
  end
end
