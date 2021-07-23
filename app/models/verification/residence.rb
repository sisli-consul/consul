class Verification::Residence
  include ActiveModel::Model
  include ActiveModel::Dates
  include ActiveModel::Validations::Callbacks

  attr_accessor :user, :document_number, :document_type, :phone_number, :terms_of_service

  before_validation :retrieve_census_data

  validates :document_number, presence: true
  validates :document_type, presence: true
  validates :phone_number, presence: true
  validates :terms_of_service, acceptance: { allow_nil: false }

  validate :document_number_uniqueness

  validate :local_residence

  def initialize(attrs = {})
    super
    clean_document_number
  end

  def save
    return false unless valid?

    user.take_votes_if_erased_document(document_number, document_type)

    user.update(document_number:       document_number,
                document_type:         document_type,
                name:                  name,
                geozone:               geozone,
                gender:                gender,
                unconfirmed_phone:     phone_number,
                sms_confirmation_code: generate_confirmation_code,
                residence_verified_at: Time.current,
                level_two_verified_at: Time.current)
  end

  def save!
    validate! && save
  end

  def store_failed_attempt
    FailedCensusCall.create(
      user: user,
      document_number: document_number,
      document_type: document_type,
      phone_number: phone_number
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

    def generate_confirmation_code
      rand.to_s[2..5]
    end

    def document_number_uniqueness
      if User.active.where(document_number: document_number).any?
        errors.add(:document_number, I18n.t("errors.messages.taken"))
      end
    end

    def local_residence
      return if errors.any?

      unless @census_data.valid?
        errors.add(:local_residence, false)
        store_failed_attempt
        Lock.increase_tries(user)
      end
    end
end
