namespace :verified_users do
  desc "Refresh local census data and Unverify outdated verified users"
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

    print "Unverifying outdated verified users..."
    User.level_three_verified.find_each.with_index do |user, index|
      unless [user.administrator?,
              user.moderator?,
              user.valuator?,
              user.official?,
              user.manager?,
              user.sdg_manager?,
              user.poll_officer?,
              user.organization?
             ].any?
        unless LocalCensusRecord.find_by(document_number: user.document_number,
                                         document_type: user.document_type,
                                         phone_number: user.phone_number,
                                         neighborhood: Geozone.find(user.geozone_id).name)
          user.update!(gender: nil,
                       sms_confirmation_code: nil,
                       unconfirmed_phone: nil,
                       confirmed_phone: nil,
                       phone_number: nil,
                       document_number: nil,
                       document_type: nil,
                       geozone_id: nil,
                       residence_verified_at: nil,
                       level_two_verified_at: nil,
                       verified_at: nil)
        end
      end
      print "." if index % 100 == 0
    end
    puts "\nOudated verified users unverified successfully."
  end
end
