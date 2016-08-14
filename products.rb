#!/usr/bin/env ruby

require 'flowcommerce'
load 'lib/flow_solidus_v0_client.rb'
load 'lib/util.rb'
load 'lib/solidus_helpers.rb'
load 'lib/solidus_taxonomy.rb'
load 'lib/solidus_product.rb'
include SolidusHelpers

solidus_token = Util.read_key(File.expand_path(File.join(File.dirname(__FILE__), '/../keys/services/solidus.txt')))

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

items = [
  {
    "id" => "sku-1",
    "name" => "Test",
    "description" => "Test description",
    "price" => "15.19",
    "categories" => ["Tops"],
    "attributes" => {
      "color" => "blue",
      "product_id" => "5"
    }
  },

  {
    "id" => "sku-2",
    "name" => "Test 2",
    "description" => "Test 2 description",
    "price" => "20.19",
    "categories" => ["Tops"],
    "attributes" => {
      "color" => "red",
      "product_id" => "5"
    }
  },

  {
    "id" => "sku-3",
    "name" => "Test 3",
    "description" => "Test 3 description",
    "price" => "20.19",
    "categories" => ["Tops"],
    "attributes" => {
      "color" => "red",
      "product_id" => "5"
    }
  }
]

items.each do |item|

  response = with_404_as_nil do
    solidus.request("/variants").with_query(
      "q\[sku_matches\]" => item['id']
    ).get
  end
  #puts response['variants'].first.inspect
  variant = ::Io::Flow::Solidus::V0::Models::ResponseVariants.new(response).variants.find { |v| v.sku == item['id'] }

  if variant
    puts "Variant sku[%s] already exists" % variant.sku
  else
    product = create_product(solidus, st, taxonomy, item['name'], item['description'], item['categories'], to_cents(item['price']))
    puts "Created product id[%s] name[%s]" % [product.id, product.name]

    form = ::Io::Flow::Solidus::V0::Models::VariantForm.new(
      :sku=> item['id'],
      :price => to_cents(item['price']),
      :cost_price => to_cents(item['price']),
      :is_master => true,
      :options => item['attributes'].map do |key, value|
        ::Io::Flow::Solidus::V0::Models::Option.new(:name => key, :value => value)
      end
    )

    puts form.inspect

    variant = solidus.products.post_variants_by_product_slug(
      product.slug,
      ::Io::Flow::Solidus::V0::Models::VariantRequestForm.new(
        :variant => form
      )
    )

    puts "Created variant %s" % variant.inspect
  end
end



