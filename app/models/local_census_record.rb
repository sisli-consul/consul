class LocalCensusRecord < ApplicationRecord
  before_validation :sanitize

  validates :document_number, presence: true
  validates :document_type, presence: true
  validates :document_type, inclusion: { in: ["1", "2", "3"], allow_blank: true }
  validates :phone_number, presence: true
  validates :neighborhood, presence: true
  validates :document_number, uniqueness: { scope: :document_type }

  scope :search, ->(terms) { where("document_number ILIKE ?", "%#{terms}%") }

  private

    def sanitize
      self.document_type   = self.document_type&.strip
      self.document_number = self.document_number&.strip
      self.phone_number = self.phone_number&.strip
    end
end
