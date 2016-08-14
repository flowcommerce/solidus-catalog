#
# taxonomy = st.upsert_taxonomy("Womens")
# puts " - %s[%s]" % [taxonomy.name, taxonomy.id]
# 
# categories = {}
# categories["Tops"] = st.upsert_taxon(taxonomy, "Tops")
# categories["Bottoms"] = st.upsert_taxon(taxonomy, "Bottoms")
# 
# categories.keys.sort.each do |name|
#   taxon = categories[name]
#   puts "   - %s[%s]" % [taxon.name, taxon.id]
# end
# 
# st.delete_taxonomy(11)
# 
class SolidusTaxonomy

  def initialize(client)
    @client = client
  end
  
  def delete_taxonomy(id)
    with_404_as_nil do
      @client.taxonomies.delete_by_id(id)
    end
  end

  def upsert_taxonomy(name)
    taxonomy = @client.taxonomies.get.taxonomies.find { |t| t.name == name }
    if taxonomy.nil?
      taxonomy = @client.taxonomies.post(
        ::Io::Flow::Solidus::V0::Models::TaxonomyForm.new(
        :name => "Womens"
      )
      )
    end
    taxonomy
  end
  
  def get_all_taxons(taxonomy, page=0, results=[])
    taxons = @client.taxons.get(taxonomy.id, :page => page).taxons

    taxons.each do |t|
      results << t
    end

    if taxons.empty?
      results
    else
      get_all_taxons(taxonomy, page+1, results)
    end
  end

  def upsert_taxon(taxonomy, name)
    taxon = get_all_taxons(taxonomy).find { |t| t.name == name }

    if taxon.nil?
      taxon = @client.taxons.post(
        taxonomy.id,
        ::Io::Flow::Solidus::V0::Models::TaxonForm.new(
          :name => name
        )
      )
    end

    taxon
  end

end
