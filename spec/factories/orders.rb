FactoryBot.define do
  factory :order do
    association :customer
    status { :pending }
    currency { "USD" }
    total_cents { 0 }

    trait :paid do
      status { :paid }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
