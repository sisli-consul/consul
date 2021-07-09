require "rails_helper"

describe LocalCensus do
  let(:api) { LocalCensus.new }

  describe "#call" do
    it "returns the response for call to the local census records" do
      allow_any_instance_of(LocalCensus::Response).to receive(:valid?).and_return true
      expect(LocalCensusRecord).to receive(:find_by).with(document_type: 1,
                                                          document_number: "12345678Z",
                                                          phone_number: "5555555555")

      expect(api.call(1, "12345678Z", "5555555555")).to be_valid
    end
  end
end
