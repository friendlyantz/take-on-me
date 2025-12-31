FactoryBot.define do
  factory :challenge_participant do
    user
    challenge_story
    name { user.username }
    status { :active }

    trait :inactive do
      status { :inactive }
    end
  end
end
