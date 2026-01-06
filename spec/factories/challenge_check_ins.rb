FactoryBot.define do
  factory :challenge_check_in do
    challenge_participant
    challenge_story { challenge_participant.challenge_story }
    message { "Today I made progress on my challenge!" }

    trait :with_photo do
      after(:build) do |check_in|
        check_in.photo.attach(
          io: StringIO.new("fake image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
