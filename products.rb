#!/usr/bin/env ruby

require 'flowcommerce'
load 'lib/flow_solidus_v0_client.rb'
load 'lib/util.rb'
load 'lib/solidus_helpers.rb'
load 'lib/solidus_taxonomy.rb'
load 'lib/solidus_product.rb'
include SolidusHelpers

org = ARGV.shift.to_s.strip
if org == ""
  puts "ERROR: Please provide organization"
  exit(1)
end

solidus_token = Util.read_key(File.expand_path(File.join(File.dirname(__FILE__), '/../keys/services/solidus.txt')))

flow = FlowCommerce.instance

def each_flow_item(client, org, opts={}, &block)
  limit = opts[:limit] || 100
  offset = opts[:offset] || 0
  
  items = client.items.get(org, :limit => limit, :offset => offset)

  items.each do |item|
    yield item
  end

  if items.size >= limit
    each_flow_item(client, org, { :limit => limit, :offset => offset + limit }, &block)
  end
end

solidus = Io::Flow::Solidus::V0::Client.at_base_url(
  :default_headers => {'X-Spree-Token' => solidus_token}
)

st = SolidusTaxonomy.new(solidus)
taxonomy = st.upsert_taxonomy("Womens")

sp = SolidusProduct.new(solidus)

def create_product(client, st, taxonomy, name, description, categories, price)
  taxon_ids = categories.map { |c| st.upsert_taxon(taxonomy, c).id }

  client.products.post(
    ::Io::Flow::Solidus::V0::Models::ProductRequestForm.new(
      :product => ::Io::Flow::Solidus::V0::Models::ProductForm.new(
        :name => name,
        :description => description,
        :taxon_ids => taxon_ids,
        :price => price,
        :shipping_category_id => 1
      )
    )
  )
end

each_flow_item(flow, org, :limit => 5) do |item|
  puts "%s/%s" % [org, item.number]

  response = with_404_as_nil do
    solidus.request("/variants").with_query(
      "q\[sku_matches\]" => item.number
    ).get
  end
  #puts response['variants'].first.inspect
  variant = ::Io::Flow::Solidus::V0::Models::ResponseVariants.new(response).variants.find { |v| v.sku == item.number }

  dims = item.dimensions.product || item.dimensions.packaging
  if dims
    height = dims.height.value
    weight = dims.weight.value
    depth = dims.depth.value
  else
    height = weight = depth = nil
  end
    
  form = ::Io::Flow::Solidus::V0::Models::VariantForm.new(
    :sku=> item.number,
    :price => to_cents(item.price.amount),
    :cost_price => to_cents(item.price.amount),
    :is_master => true,
    :height => height,
    :weight => weight,
    :depth => depth,
    :options => item.attributes.map do |key, value|
      ::Io::Flow::Solidus::V0::Models::Option.new(:name => key, :value => value)
    end
  )

  puts form.inspect
  exit(1)
  
  if variant
    ## TODO: Update once we figure out how to get product id
    puts "  - variant sku[%s] already exists" % variant.sku
  else
    product = create_product(solidus, st, taxonomy, item.name, item.description, item.categories, to_cents(item.price.amount))
    puts "  - created product id[%s] name[%s]" % [product.id, product.name]

    variant = solidus.products.post_variants_by_product_slug(
      product.slug,
      ::Io::Flow::Solidus::V0::Models::VariantRequestForm.new(
        :variant => form
      )
    )

    puts "  - created variant sku[%s]" % variant.sku
  end
end



