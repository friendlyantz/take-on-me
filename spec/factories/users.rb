FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    webauthn_id { WebAuthn.generate_user_id }

    trait :with_credential do
      after(:create) do |user|
        create(:credential, user: user)
      end
    end
  end
end
