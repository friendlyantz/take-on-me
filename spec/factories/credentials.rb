FactoryBot.define do
  factory :credential do
    user
    sequence(:external_id) { |n| Base64.strict_encode64("credential_#{n}") }
    public_key { "fake_public_key_#{SecureRandom.hex(16)}" }
    sequence(:nickname) { |n| "Device #{n}" }
    sign_count { 0 }
  end
end
