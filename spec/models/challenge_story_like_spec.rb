require "rails_helper"

RSpec.describe ChallengeStoryLike, type: :model do
  describe "validations" do
    it "prevents duplicate likes from same user" do
      user = create(:user)
      story = create(:challenge_story)
      create(:challenge_story_like, user: user, challenge_story: story)

      duplicate = build(:challenge_story_like, user: user, challenge_story: story)

      expect(duplicate).not_to be_valid
    end

    it "allows different users to like same story" do
      story = create(:challenge_story)
      create(:challenge_story_like, challenge_story: story)

      another_like = build(:challenge_story_like, challenge_story: story)

      expect(another_like).to be_valid
    end
  end
end
