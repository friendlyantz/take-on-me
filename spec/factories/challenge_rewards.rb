FactoryBot.define do
  factory :challenge_reward do
    association :giver, factory: :challenge_participant
    association :receiver, factory: :challenge_participant
    challenge_story { giver.challenge_story }
    description { "I'll buy you coffee if you complete this!" }
    status { :pending }

    trait :fulfilled do
      status { :fulfilled }
      fulfilled_at { Time.current }
    end

    trait :canceled do
      status { :canceled }
    end
  end
end
