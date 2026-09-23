FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    quantity { 2 }
    unit_price_cents { 1999 }
    subtotal_cents { 3998 }
  end
end
