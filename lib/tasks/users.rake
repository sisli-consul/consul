namespace :users do
  desc "Unverify outdated verified users"
  task update_verified: :environment do
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
                                         document_type: user.document_type)
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
