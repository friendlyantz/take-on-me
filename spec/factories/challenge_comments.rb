FactoryBot.define do
  factory :challenge_comment do
    challenge_participant
    challenge_story { challenge_participant.challenge_story }
    message { "Today I made progress on my challenge!" }

    trait :with_photo do
      after(:build) do |comment|
        comment.photo.attach(
          io: StringIO.new("fake image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
