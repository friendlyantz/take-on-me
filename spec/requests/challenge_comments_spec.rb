require "rails_helper"

RSpec.describe "ChallengeComments", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:challenge_story) }
  let!(:participant) { create(:challenge_participant, user: user, challenge_story: story) }

  describe "GET /challenge_stories/:challenge_story_id/challenge_comments/new" do
    context "when not signed in" do
      it "redirects to sign in" do
        get new_challenge_story_challenge_comment_path(story)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in but not a participant" do
      let(:other_user) { create(:user) }

      before { sign_in_as(other_user) }

      it "redirects with alert" do
        get new_challenge_story_challenge_comment_path(story)

        expect(response).to redirect_to(challenge_story_path(story))
        expect(flash[:alert]).to include("participant")
      end
    end

    context "when signed in as a participant" do
      before { sign_in_as(user) }

      it "returns the new comment form" do
        get new_challenge_story_challenge_comment_path(story)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /challenge_stories/:challenge_story_id/challenge_comments" do
    before { sign_in_as(user) }

    context "with valid params" do
      let(:valid_params) { {challenge_comment: {message: "Today's check-in!"}} }

      it "creates a new comment" do
        expect {
          post challenge_story_challenge_comments_path(story), params: valid_params
        }.to change(ChallengeComment, :count).by(1)

        expect(response).to redirect_to(challenge_story_path(story))
      end
    end

    context "with invalid params" do
      let(:invalid_params) { {challenge_comment: {message: ""}} }

      it "does not create a comment" do
        expect {
          post challenge_story_challenge_comments_path(story), params: invalid_params
        }.not_to change(ChallengeComment, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when story is completed" do
      before { story.update!(completed: true) }

      it "redirects with alert" do
        post challenge_story_challenge_comments_path(story), params: {challenge_comment: {message: "Test"}}

        expect(response).to redirect_to(challenge_story_path(story))
        expect(flash[:alert]).to include("completed")
      end
    end

    context "when already checked in today" do
      before do
        create(:challenge_comment, challenge_participant: participant, challenge_story: story)
      end

      it "does not allow duplicate check-in" do
        expect {
          post challenge_story_challenge_comments_path(story), params: {challenge_comment: {message: "Another check-in"}}
        }.not_to change(ChallengeComment, :count)
      end
    end
  end
end
