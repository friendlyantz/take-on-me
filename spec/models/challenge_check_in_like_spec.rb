require "rails_helper"

RSpec.describe ChallengeCheckInLike, type: :model do
  describe "validations" do
    it "prevents duplicate likes from same user" do
      user = create(:user)
      check_in = create(:challenge_check_in)
      create(:challenge_check_in_like, user: user, challenge_check_in: check_in)

      duplicate = build(:challenge_check_in_like, user: user, challenge_check_in: check_in)

      expect(duplicate).not_to be_valid
    end

    it "allows different users to like same check-in" do
      check_in = create(:challenge_check_in)
      create(:challenge_check_in_like, challenge_check_in: check_in)

      another_like = build(:challenge_check_in_like, challenge_check_in: check_in)

      expect(another_like).to be_valid
    end
  end
end
