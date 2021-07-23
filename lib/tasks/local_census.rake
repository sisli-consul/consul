namespace :local_census do
  desc "Refresh local census data"
  task update: :environment do
    puts "Deleting old data ..."
    LocalCensusRecord.find_each(&:destroy!)
    puts "Old data deleted successfully!"

    models = [ImportedUserFirst, ImportedUserSecond, ImportedUserThird]

    models.each do |model|
      print "Importing data from table '#{model.table_name}' ..."

      model.find_each.with_index do |user, index|
        if user.valid?
          phone_number = "90".concat user.phone_number
          existing_record = LocalCensusRecord.find_by(document_number: user.document_number,
                                                      document_type: "1")

          unless existing_record.present?
            LocalCensusRecord.create!(document_number: user.document_number,
                                      document_type: "1",
                                      name: user.name,
                                      phone_number: phone_number,
                                      gender: user.gender,
                                      neighborhood: user.neighborhood)
          end
        end
        print "." if index % 100 == 0
      end
      puts "\nData from table '#{model.table_name}' imported successfully!"
    end
    puts "local_census_records database update finished!"
  end
end
