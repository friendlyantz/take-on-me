require "rails_helper"

RSpec.describe ChallengeReward, type: :model do
  let(:story) { create(:challenge_story) }
  let(:giver) { create(:challenge_participant, challenge_story: story) }
  let(:receiver) { create(:challenge_participant, challenge_story: story) }

  describe "validations" do
    describe "cannot_reward_self" do
      it "prevents giver and receiver from being the same" do
        reward = build(:challenge_reward, giver: giver, receiver: giver, challenge_story: story)

        expect(reward).not_to be_valid
        expect(reward.errors[:receiver_id]).to include("can't be the same as giver")
      end
    end

    describe "participants_in_same_challenge" do
      it "prevents rewards between participants in different challenges" do
        other_story = create(:challenge_story)
        other_participant = create(:challenge_participant, challenge_story: other_story)

        reward = build(:challenge_reward, giver: giver, receiver: other_participant, challenge_story: story)

        expect(reward).not_to be_valid
        expect(reward.errors[:base]).to include("Both participants must be in the same challenge")
      end
    end

    describe "uniqueness" do
      it "prevents duplicate rewards from same giver to same receiver" do
        create(:challenge_reward, giver: giver, receiver: receiver, challenge_story: story)
        duplicate = build(:challenge_reward, giver: giver, receiver: receiver, challenge_story: story)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:giver_id]).to include("has already pledged a reward to this participant")
      end
    end
  end

  describe "#fulfill!" do
    let(:reward) { create(:challenge_reward, giver: giver, receiver: receiver, challenge_story: story) }

    it "marks reward as fulfilled" do
      reward.fulfill!

      expect(reward.reload).to be_fulfilled
    end

    it "sets fulfilled_at timestamp" do
      reward.fulfill!

      expect(reward.reload.fulfilled_at).to be_present
    end
  end

  describe "#cancel!" do
    let(:reward) { create(:challenge_reward, giver: giver, receiver: receiver, challenge_story: story) }

    it "marks reward as canceled" do
      reward.cancel!

      expect(reward.reload).to be_canceled
    end
  end

  describe "scopes" do
    let!(:pending_reward) { create(:challenge_reward, giver: giver, receiver: receiver, challenge_story: story) }

    describe ".pending" do
      it "returns pending rewards" do
        expect(ChallengeReward.pending).to eq([pending_reward])
      end
    end

    describe ".fulfilled" do
      it "returns fulfilled rewards" do
        pending_reward.fulfill!

        expect(ChallengeReward.fulfilled).to eq([pending_reward])
        expect(ChallengeReward.pending).to be_empty
      end
    end

    describe ".canceled" do
      it "returns canceled rewards" do
        pending_reward.cancel!

        expect(ChallengeReward.canceled).to eq([pending_reward])
        expect(ChallengeReward.pending).to be_empty
      end
    end
  end
end
