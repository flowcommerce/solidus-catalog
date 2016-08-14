class SolidusProduct

  include SolidusHelpers

  def initialize(client)
    @client = client
  end
  
  def delete_product(id)
    with_404_as_nil do
      @client.products.delete_by_id(id)
    end
  end

end
