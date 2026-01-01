FactoryBot.define do
  factory :challenge_story do
    sequence(:title) { |n| "Challenge #{n}" }
    description { "A test challenge description" }
    start { Time.zone.today }
    finish { Time.zone.today + 7.days }
    completed { false }

    trait :completed do
      completed { true }
    end

    trait :finished do
      start { Time.zone.today - 10.days }
      finish { Time.zone.today - 3.days }
    end

    trait :with_participant do
      transient do
        participant_user { nil }
      end

      after(:create) do |story, evaluator|
        user = evaluator.participant_user || create(:user)
        create(:challenge_participant, challenge_story: story, user: user)
      end
    end
  end
end
