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

  describe "#has_pledged_to_all_active_participants?" do
    let(:story) { create(:challenge_story) }
    let(:participant1) { create(:challenge_participant, challenge_story: story) }
    let(:participant2) { create(:challenge_participant, challenge_story: story) }
    let(:participant3) { create(:challenge_participant, challenge_story: story) }

    context "when there are no other active participants" do
      it "returns true" do
        solo_participant = create(:challenge_participant, challenge_story: create(:challenge_story))

        expect(solo_participant.has_pledged_to_all_active_participants?).to be true
      end
    end

    context "when pledged to all active participants" do
      it "returns true" do
        create(:challenge_reward, giver: participant1, receiver: participant2, challenge_story: story)
        create(:challenge_reward, giver: participant1, receiver: participant3, challenge_story: story)

        expect(participant1.has_pledged_to_all_active_participants?).to be true
      end
    end

    context "when not pledged to all active participants" do
      before do
        # Ensure all participants exist
        participant1
        participant2
        participant3
      end

      it "returns false" do
        create(:challenge_reward, giver: participant1, receiver: participant2, challenge_story: story)

        expect(participant1.has_pledged_to_all_active_participants?).to be false
      end
    end

    context "when inactive participants exist" do
      it "ignores inactive participants" do
        create(:challenge_participant, :inactive, challenge_story: story)
        create(:challenge_reward, giver: participant1, receiver: participant2, challenge_story: story)
        create(:challenge_reward, giver: participant1, receiver: participant3, challenge_story: story)

        expect(participant1.has_pledged_to_all_active_participants?).to be true
      end
    end
  end

  describe "#unpledged_participants" do
    let(:story) { create(:challenge_story) }
    let(:participant1) { create(:challenge_participant, challenge_story: story) }
    let(:participant2) { create(:challenge_participant, challenge_story: story) }
    let(:participant3) { create(:challenge_participant, challenge_story: story) }

    it "returns participants without pledges" do
      create(:challenge_reward, giver: participant1, receiver: participant2, challenge_story: story)
      participant3 # ensure participant3 exists

      expect(participant1.unpledged_participants).to contain_exactly(participant3)
    end

    it "excludes inactive participants" do
      create(:challenge_participant, :inactive, challenge_story: story)
      participant2 # ensure participant2 exists
      participant3 # ensure participant3 exists

      expect(participant1.unpledged_participants).to contain_exactly(participant2, participant3)
    end

    it "excludes self" do
      participant2 # ensure participant2 exists
      participant3 # ensure participant3 exists

      expect(participant1.unpledged_participants).not_to include(participant1)
    end
  end

  describe "#missing_pledges?" do
    let(:story) { create(:challenge_story) }
    let(:participant1) { create(:challenge_participant, challenge_story: story) }
    let(:participant2) { create(:challenge_participant, challenge_story: story) }

    it "returns true when pledges are missing" do
      participant1
      participant2 # ensure participant2 exists

      expect(participant1.missing_pledges?).to be true
    end

    it "returns false when all pledges are made" do
      create(:challenge_reward, giver: participant1, receiver: participant2, challenge_story: story)

      expect(participant1.missing_pledges?).to be false
    end
  end
end
