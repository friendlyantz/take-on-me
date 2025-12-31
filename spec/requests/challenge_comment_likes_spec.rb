require "rails_helper"

RSpec.describe "ChallengeCommentLikes", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:challenge_story) }
  let(:participant) { create(:challenge_participant, challenge_story: story) }
  let(:comment) { create(:challenge_comment, challenge_participant: participant, challenge_story: story) }

  describe "POST /challenge_comments/:challenge_comment_id/challenge_comment_like" do
    context "when not signed in" do
      it "redirects to sign in" do
        post challenge_comment_challenge_comment_like_path(comment)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates a like" do
        expect {
          post challenge_comment_challenge_comment_like_path(comment)
        }.to change(ChallengeCommentLike, :count).by(1)
      end

      it "increments the counter cache" do
        expect {
          post challenge_comment_challenge_comment_like_path(comment)
        }.to change { comment.reload.challenge_comment_likes_count }.by(1)
      end
    end
  end

  describe "DELETE /challenge_comments/:challenge_comment_id/challenge_comment_like" do
    let!(:like) { create(:challenge_comment_like, user: user, challenge_comment: comment) }

    before { sign_in_as(user) }

    it "destroys the like" do
      expect {
        delete challenge_comment_challenge_comment_like_path(comment)
      }.to change(ChallengeCommentLike, :count).by(-1)
    end

    it "decrements the counter cache" do
      expect {
        delete challenge_comment_challenge_comment_like_path(comment)
      }.to change { comment.reload.challenge_comment_likes_count }.by(-1)
    end
  end
end
