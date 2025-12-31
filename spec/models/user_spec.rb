require "rails_helper"

RSpec.describe User, type: :model do
  describe "#can_delete_credentials?" do
    let(:user) { create(:user) }

    it "returns false when user has only one credential" do
      create(:credential, user: user)

      expect(user.can_delete_credentials?).to be false
    end

    it "returns true when user has more than one credential" do
      create_list(:credential, 2, user: user)

      expect(user.can_delete_credentials?).to be true
    end
  end

  describe "#latest_active_participation" do
    let(:user) { create(:user) }

    it "returns nil when user has no participations" do
      expect(user.latest_active_participation).to be_nil
    end

    it "returns nil when all participations are inactive" do
      create(:challenge_participant, :inactive, user: user)

      expect(user.latest_active_participation).to be_nil
    end

    it "returns nil when all stories are completed" do
      story = create(:challenge_story, :completed)
      create(:challenge_participant, user: user, challenge_story: story)

      expect(user.latest_active_participation).to be_nil
    end

    it "returns the most recently updated active participation" do
      old_story = create(:challenge_story, updated_at: 2.days.ago)
      new_story = create(:challenge_story, updated_at: 1.day.ago)

      create(:challenge_participant, user: user, challenge_story: old_story)
      latest = create(:challenge_participant, user: user, challenge_story: new_story)

      expect(user.latest_active_participation).to eq(latest)
    end
  end

  describe "callbacks" do
    it "sets webauthn_id on initialize" do
      user = User.new

      expect(user.webauthn_id).to be_present
    end
  end
end
