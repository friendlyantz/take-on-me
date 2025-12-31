require "rails_helper"

RSpec.describe "ChallengeStoryLikes", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:challenge_story) }

  describe "POST /challenge_stories/:challenge_story_id/challenge_story_like" do
    context "when not signed in" do
      it "redirects to sign in" do
        post challenge_story_challenge_story_like_path(story)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates a like" do
        expect {
          post challenge_story_challenge_story_like_path(story)
        }.to change(ChallengeStoryLike, :count).by(1)
      end

      it "increments the counter cache" do
        expect {
          post challenge_story_challenge_story_like_path(story)
        }.to change { story.reload.challenge_story_likes_count }.by(1)
      end
    end
  end

  describe "DELETE /challenge_stories/:challenge_story_id/challenge_story_like" do
    let!(:like) { create(:challenge_story_like, user: user, challenge_story: story) }

    before { sign_in_as(user) }

    it "destroys the like" do
      expect {
        delete challenge_story_challenge_story_like_path(story)
      }.to change(ChallengeStoryLike, :count).by(-1)
    end

    it "decrements the counter cache" do
      expect {
        delete challenge_story_challenge_story_like_path(story)
      }.to change { story.reload.challenge_story_likes_count }.by(-1)
    end
  end
end
