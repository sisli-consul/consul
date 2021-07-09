include DocumentParser
class LocalCensus
  def call(document_type, document_number, phone_number)
    Response.new get_record(document_type, document_number, phone_number)
  end

  class Response
    def initialize(body)
      @body = body
    end

    def valid?
      @body.present?
    end

    def date_of_birth
      @body.date_of_birth
    end

    def postal_code
      @body.postal_code
    end

    def phone_number
      @body.phone_number
    end

    def district_code
      @body.neighborhood
    end

    def gender
      case @body.gender.upcase
      when "ERKEK"
        "male"
      when "KADIN"
        "female"
      else
        nil
      end
    end

    def name
      @body.name
    end

    def surname
      @body.surname
    end

    private

      def data
        @body.attributes
      end
  end

  private

    def get_record(document_type, document_number, phone_number)
      LocalCensusRecord.find_by(document_type: document_type,
                                document_number: document_number,
                                phone_number: phone_number)
    end
end
