FactoryBot.define do
  factory :customer do
    name { Faker::Name.name }
    sequence(:email) { |n| "customer#{n}@example.com" }
    status { "active" }
  end
end
