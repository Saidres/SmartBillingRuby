FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    sequence(:sku) { |n| "SKU-#{n.to_s.rjust(5, '0')}" }
    description { Faker::Lorem.sentence }
    price_cents { 1999 } # $19.99
    stock { 50 }
    active { true }

    trait :out_of_stock do
      stock { 0 }
    end

    trait :inactive do
      active { false }
    end
  end
end
