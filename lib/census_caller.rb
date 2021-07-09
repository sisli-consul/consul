class CensusCaller
  def call(document_type, document_number, phone_number)
    return Response.new if document_number.blank? || document_type.blank? || phone_number.blank?

    LocalCensus.new.call(document_type, document_number, phone_number)
  end

  class Response
    def valid?
      false
    end
  end
end
