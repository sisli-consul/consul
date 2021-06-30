module ImportValidation
  extend ActiveSupport::Concern

  def document_number
    field_name :tckn
  end

  def phone_number
    field_name(:ceptel).delete("+( )").last(10)
  end

  def gender
    field_name :cinsiyet
  end

  def name
    field_name :adsoyad
  end

  def neighborhood
    field_name :mahalle
  end

  def valid?
    return false unless valid_phone_number?
    return false unless valid_neighborhood?

    valid_document_number?
  end

  private

    def field_name(name)
      attributes.deep_symbolize_keys![name].to_s
    end

    def valid_document_number?
      return false if document_number.size != 11
      return false if document_number.starts_with?("0")

      x = 0
      [0, 2, 4, 6, 8].each do |i|
        x += document_number[i].to_i
      end

      y = 0
      [1, 3, 5, 7].each do |i|
        y += document_number[i].to_i
      end

      tenth_digit = document_number.last(2).first.to_i
      last_digit = document_number.last.to_i

      return false unless (x * 7 - y) % 10 == tenth_digit

      (x + y + tenth_digit) % 10 == last_digit
    end

    def valid_phone_number?
      phone_number.size == 10 && phone_number.starts_with?("5")
    end

    def valid_neighborhood?
      Geozone.pluck(:name).map(&:upcase).include?(neighborhood.upcase)
    end
end
