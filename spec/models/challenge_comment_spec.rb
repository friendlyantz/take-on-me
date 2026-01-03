require "rails_helper"

RSpec.describe ChallengeComment, type: :model do
  describe "validations" do
    describe "one_comment_per_day_per_participant" do
      let(:challenge_participant) { create(:challenge_participant) }
      let(:story) { challenge_participant.challenge_story }

      it "allows first comment of the day" do
        comment = build(:challenge_comment, challenge_participant: challenge_participant, challenge_story: story)

        expect(comment).to be_valid
      end

      it "prevents second comment on same day" do
        create(:challenge_comment, challenge_participant: challenge_participant, challenge_story: story)
        second_comment = build(:challenge_comment, challenge_participant: challenge_participant, challenge_story: story)

        expect(second_comment).not_to be_valid
        expect(second_comment.errors[:base]).to include("You can only check in once per day")
      end

      it "allows comment on different day" do
        create(:challenge_comment, challenge_participant: challenge_participant, challenge_story: story, created_at: 1.day.ago)
        today_comment = build(:challenge_comment, challenge_participant: challenge_participant, challenge_story: story)

        expect(today_comment).to be_valid
      end
    end
  end

  describe "#liked_by?" do
    let(:comment) { create(:challenge_comment) }
    let(:user) { create(:user) }

    it "returns false when user is nil" do
      expect(comment.liked_by?(nil)).to be false
    end

    it "returns false when user has not liked" do
      expect(comment.liked_by?(user)).to be false
    end

    it "returns true when user has liked" do
      create(:challenge_comment_like, user: user, challenge_comment: comment)

      expect(comment.liked_by?(user)).to be true
    end
  end
end
