require "rails_helper"

RSpec.describe ChallengeCommentLike, type: :model do
  describe "validations" do
    it "prevents duplicate likes from same user" do
      user = create(:user)
      comment = create(:challenge_comment)
      create(:challenge_comment_like, user: user, challenge_comment: comment)

      duplicate = build(:challenge_comment_like, user: user, challenge_comment: comment)

      expect(duplicate).not_to be_valid
    end

    it "allows different users to like same comment" do
      comment = create(:challenge_comment)
      create(:challenge_comment_like, challenge_comment: comment)

      another_like = build(:challenge_comment_like, challenge_comment: comment)

      expect(another_like).to be_valid
    end
  end
end
