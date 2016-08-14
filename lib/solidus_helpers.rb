module SolidusHelpers

  # Price in cents
  def to_cents(price)
    BigDecimal.new(price) * 100
  end

  def with_404_as_nil(&block)
    begin
      block.call
    rescue Io::Flow::Solidus::V0::HttpClient::ServerError => e
      case e.code
      when 404
      # no-op
      else
        raise e
      end
    end
  end  

end
