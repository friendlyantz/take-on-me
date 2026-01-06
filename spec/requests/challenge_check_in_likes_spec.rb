require "rails_helper"

RSpec.describe "ChallengeCheckInLikes", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:challenge_story) }
  let(:participant) { create(:challenge_participant, challenge_story: story) }
  let(:check_in) { create(:challenge_check_in, challenge_participant: participant, challenge_story: story) }

  describe "POST /challenge_check_ins/:challenge_check_in_id/challenge_check_in_like" do
    context "when not signed in" do
      it "redirects to sign in" do
        post challenge_check_in_challenge_check_in_like_path(check_in)

        expect(response).to redirect_to(new_webauthn_session_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates a like" do
        expect {
          post challenge_check_in_challenge_check_in_like_path(check_in)
        }.to change(ChallengeCheckInLike, :count).by(1)
      end

      it "increments the counter cache" do
        expect {
          post challenge_check_in_challenge_check_in_like_path(check_in)
        }.to change { check_in.reload.challenge_check_in_likes_count }.by(1)
      end
    end
  end

  describe "DELETE /challenge_check_ins/:challenge_check_in_id/challenge_check_in_like" do
    let!(:like) { create(:challenge_check_in_like, user: user, challenge_check_in: check_in) }

    before { sign_in_as(user) }

    it "destroys the like" do
      expect {
        delete challenge_check_in_challenge_check_in_like_path(check_in)
      }.to change(ChallengeCheckInLike, :count).by(-1)
    end

    it "decrements the counter cache" do
      expect {
        delete challenge_check_in_challenge_check_in_like_path(check_in)
      }.to change { check_in.reload.challenge_check_in_likes_count }.by(-1)
    end
  end
end
