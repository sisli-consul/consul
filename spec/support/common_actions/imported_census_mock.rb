module ImportedCensusMock
  def valid_imported_census_record
    Record.new(JSON.parse(File.read("spec/fixtures/files/imported_census_data/valid.json")))
  end

  def valid_repeated_imported_census_record
    Record.new(JSON.parse(File.read("spec/fixtures/files/imported_census_data/valid_repeated.json")))
  end

  def invalid_imported_census_record(reason)
    Record.new(JSON.parse(File.read("spec/fixtures/files/imported_census_data/invalid_#{reason}.json")))
  end

  def mock_empty_imported_census_records(model)
    expect(model).to receive(:find_each).and_return Array.new.to_enum
  end

  def mock_valid_imported_census_records(model)
    expect(model).to receive(:find_each).and_return [valid_imported_census_record].to_enum
  end

  def mock_valid_repeated_imported_census_records(model)
    expect(model).to receive(:find_each).and_return [valid_repeated_imported_census_record].to_enum
  end

  def mock_invalid_imported_census_records(model, *reasons)
    records = []
    reasons.each do |reason|
      records << invalid_imported_census_record(reason)
    end
    expect(model).to receive(:find_each).and_return records.to_enum
  end

  class Record
    include ::ImportValidation

    attr_reader :data
    alias :attributes :data

    def initialize(data)
      @data = data
    end
  end
end
