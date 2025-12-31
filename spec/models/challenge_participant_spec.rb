require "rails_helper"

RSpec.describe ChallengeParticipant, type: :model do
  describe "#leave!" do
    let(:participant) { create(:challenge_participant) }

    it "marks participant as inactive" do
      participant.leave!

      expect(participant.reload).to be_inactive
    end
  end

  describe "#rejoin!" do
    let(:participant) { create(:challenge_participant, :inactive) }

    it "marks participant as active" do
      participant.rejoin!

      expect(participant.reload).to be_active
    end
  end

  describe "callbacks" do
    describe "set_default_name" do
      it "sets name from username on create" do
        user = create(:user, username: "testuser")
        participant = create(:challenge_participant, user: user, name: nil)

        expect(participant.name).to eq("testuser")
      end
    end
  end

  describe "scopes" do
    let(:story) { create(:challenge_story) }

    describe ".active" do
      it "returns only active participants" do
        active = create(:challenge_participant, challenge_story: story, status: :active)
        create(:challenge_participant, :inactive, challenge_story: story)

        expect(ChallengeParticipant.active).to eq([active])
      end
    end

    describe ".inactive" do
      it "returns only inactive participants" do
        create(:challenge_participant, challenge_story: story, status: :active)
        inactive = create(:challenge_participant, :inactive, challenge_story: story)

        expect(ChallengeParticipant.inactive).to eq([inactive])
      end
    end
  end
end
