class Verification::Management::Document
  include ActiveModel::Model
  include ActiveModel::Dates

  attr_accessor :document_type, :document_number, :phone_number

  validates :document_type, :document_number, :phone_number, presence: true

  delegate :username, :email, to: :user, allow_nil: true

  def initialize(attrs = {})
    super
  end

  def user
    @user = User.active.by_document(document_type, document_number).first
  end

  def user?
    user.present?
  end

  def in_census?
    response = CensusCaller.new.call(document_type, document_number, phone_number)
    response.valid?
  end

  def verified?
    user? && user.level_three_verified?
  end

  def verify
    user.update(verified_at: Time.current) if user?
  end
end
