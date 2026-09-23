FactoryBot.define do
  factory :invoice do
    association :order
    currency { "USD" }
    target_currency { "EUR" }
    exchange_rate { 0.9200 }
    total_cents { 5000 }
    total_target_currency_cents { 4600 }
    status { :issued }
    issued_at { Time.current }
  end
end
