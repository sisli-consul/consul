require "rails_helper"

describe CensusCaller do
  let(:api) { CensusCaller.new }

  describe "#call" do
    let(:valid_body) do
      { get_habita_datos_response: {
        get_habita_datos_return: { datos_habitante: { item: { fecha_nacimiento_string: "1-1-1980" }}}
      }}
    end
    let(:invalid_body) do
      { get_habita_datos_response: { get_habita_datos_return: { datos_habitante: {}}}}
    end

    it "returns invalid response when document_number is empty" do
      response = api.call(1, "", "5437645321")
      expect(response).not_to be_valid
    end

    it "returns invalid response when document_type is empty" do
      response = api.call("", "12345678A", "5437645321")
      expect(response).not_to be_valid
    end

    it "returns invalid response when phone_number is empty" do
      response = api.call(1, "12345678A", "")
      expect(response).not_to be_valid
    end

    it "returns local census response" do
      local_census_response = LocalCensus::Response.new(create(:local_census_record))
      allow_any_instance_of(LocalCensus).to receive(:call).and_return(local_census_response)
      response = api.call(1, "12345678A", "5437645321")

      expect(response).to eq(local_census_response)
    end
  end
end
