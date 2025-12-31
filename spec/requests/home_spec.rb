require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when not signed in" do
      it "returns the home page" do
        get root_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in with active participation" do
      let(:user) { create(:user) }
      let(:story) { create(:challenge_story) }
      let!(:participant) { create(:challenge_participant, user: user, challenge_story: story) }

      before { sign_in_as(user) }

      it "redirects to the latest active challenge" do
        get root_path

        expect(response).to redirect_to(challenge_story_path(story))
      end
    end

    context "when signed in without active participation" do
      let(:user) { create(:user) }

      before { sign_in_as(user) }

      it "redirects to challenge stories index" do
        get root_path

        expect(response).to redirect_to(challenge_stories_path)
      end
    end
  end
end
