FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "listener#{n}@example.com" }
    password { "a long passphrase" }
  end
end
