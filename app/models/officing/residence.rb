class Officing::Residence
  include ActiveModel::Model
  include ActiveModel::Dates
  include ActiveModel::Validations::Callbacks

  attr_accessor :user, :officer, :document_number, :document_type, :phone_number

  before_validation :retrieve_census_data

  validates :document_number, presence: true
  validates :document_type, presence: true
  validates :phone_number, presence: true

  validate :local_residence

  def initialize(attrs = {})
    super
    clean_document_number
  end

  def save
    return false unless valid?

    user_params = {
      name:                  name,
      geozone:               geozone,
      gender:                gender,
      unconfirmed_phone:     phone_number,
      sms_confirmation_code: generate_confirmation_code,
      residence_verified_at: Time.current,
      level_two_verified_at: Time.current,
      verified_at:           Time.current,
      terms_of_service:      "1",
      email:                 nil,
      password:              random_password
    }
    self.user = find_user_by_document
    if self.user.present?
      user.update!(user_params)
    else
      self.user = User.create!(user_params.merge(username: document_number,
                                                 document_number: document_number,
                                                 document_type: document_type,
                                                 erased_at: Time.current))
    end
  end

  def save!
    validate! && save
  end

  def find_user_by_document
    User.find_by(document_number: document_number, document_type: document_type)
  end

  def store_failed_census_call
    FailedCensusCall.create(
      user: user,
      document_number: document_number,
      document_type: document_type,
      phone_number: phone_number,
      poll_officer: officer
    )
  end

  def geozone
    Geozone.find_by(name: district_code)
  end

  def name
    @census_data.name
  end

  def district_code
    @census_data.district_code
  end

  def gender
    @census_data.gender
  end

  private

    def retrieve_census_data
      @census_data = CensusCaller.new.call(document_type, document_number, phone_number)
    end

    def clean_document_number
      self.document_number = document_number.gsub(/[^a-z0-9]+/i, "").upcase if document_number.present?
    end

    def random_password
      (0...20).map { ("a".."z").to_a[rand(26)] }.join
    end

    def generate_confirmation_code
      rand.to_s[2..5]
    end

    def local_residence
      return if errors.any?

      unless @census_data.valid?
        errors.add(:local_residence, false)
        store_failed_census_call
        Lock.increase_tries(user)
      end
    end
end
