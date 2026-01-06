require "rails_helper"

RSpec.describe ChallengeCheckIn, type: :model do
  describe "validations" do
    describe "one_comment_per_day_per_participant" do
      let(:challenge_participant) { create(:challenge_participant) }
      let(:story) { challenge_participant.challenge_story }

      it "allows first check-in of the day" do
        check_in = build(:challenge_check_in, challenge_participant: challenge_participant, challenge_story: story)

        expect(check_in).to be_valid
      end

      it "prevents second check-in on same day" do
        create(:challenge_check_in, challenge_participant: challenge_participant, challenge_story: story)
        second_check_in = build(:challenge_check_in, challenge_participant: challenge_participant, challenge_story: story)

        expect(second_check_in).not_to be_valid
        expect(second_check_in.errors[:base]).to include("You can only check in once per day")
      end

      it "allows check-in on different day" do
        create(:challenge_check_in, challenge_participant: challenge_participant, challenge_story: story, created_at: 1.day.ago)
        today_check_in = build(:challenge_check_in, challenge_participant: challenge_participant, challenge_story: story)

        expect(today_check_in).to be_valid
      end
    end
  end

  describe "#liked_by?" do
    let(:check_in) { create(:challenge_check_in) }
    let(:user) { create(:user) }

    it "returns false when user is nil" do
      expect(check_in.liked_by?(nil)).to be false
    end

    it "returns false when user has not liked" do
      expect(check_in.liked_by?(user)).to be false
    end

    it "returns true when user has liked" do
      create(:challenge_check_in_like, user: user, challenge_check_in: check_in)

      expect(check_in.liked_by?(user)).to be true
    end
  end
end
