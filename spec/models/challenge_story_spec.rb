require "rails_helper"

RSpec.describe ChallengeStory, type: :model do
  describe "validations" do
    it "validates finish cannot be earlier than start" do
      story = build(:challenge_story, start: Time.zone.today, finish: Time.zone.today - 1.day)

      expect(story).not_to be_valid
      expect(story.errors[:finish]).to include("cannot be earlier than the start date")
    end

    it "validates description length" do
      story = build(:challenge_story, description: "a" * 501)

      expect(story).not_to be_valid
    end
  end

  describe "#finished?" do
    it "returns true when finish date is in the past" do
      story = build(:challenge_story, finish: Time.zone.today - 1.day)

      expect(story.finished?).to be true
    end

    it "returns false when finish date is today or future" do
      story = build(:challenge_story, finish: Time.zone.today)

      expect(story.finished?).to be false
    end
  end

  describe "#at_capacity?" do
    let(:story) { create(:challenge_story) }

    it "returns false when under capacity" do
      create_list(:challenge_participant, 2, challenge_story: story)

      expect(story.at_capacity?).to be false
    end

    it "returns true when at max participants" do
      create_list(:challenge_participant, ChallengeStory::MAX_PARTICIPANTS, challenge_story: story)

      expect(story.at_capacity?).to be true
    end
  end

  describe "#available_spots" do
    let(:story) { create(:challenge_story) }

    it "returns remaining spots" do
      create_list(:challenge_participant, 2, challenge_story: story)

      expect(story.available_spots).to eq(ChallengeStory::MAX_PARTICIPANTS - 2)
    end
  end

  describe "#mark_complete!" do
    let(:story) { create(:challenge_story) }

    it "marks the story as completed" do
      story.mark_complete!

      expect(story.reload).to be_completed
    end
  end

  describe "#find_or_activate_participant!" do
    let(:story) { create(:challenge_story) }
    let(:user) { create(:user) }

    context "when user is not a participant" do
      it "creates a new active participant" do
        participant = story.find_or_activate_participant!(user)

        expect(participant).to be_persisted
        expect(participant).to be_active
        expect(participant.user).to eq(user)
      end
    end

    context "when user is an inactive participant" do
      let!(:participant) { create(:challenge_participant, :inactive, user: user, challenge_story: story) }

      it "reactivates the participant" do
        result = story.find_or_activate_participant!(user)

        expect(result.id).to eq(participant.id)
        expect(result).to be_active
      end
    end

    context "when user is already active" do
      let!(:participant) { create(:challenge_participant, user: user, challenge_story: story) }

      it "returns existing participant" do
        result = story.find_or_activate_participant!(user)

        expect(result.id).to eq(participant.id)
      end
    end
  end

  describe "#liked_by?" do
    let(:story) { create(:challenge_story) }
    let(:user) { create(:user) }

    it "returns false when user is nil" do
      expect(story.liked_by?(nil)).to be false
    end

    it "returns false when user has not liked" do
      expect(story.liked_by?(user)).to be false
    end

    it "returns true when user has liked" do
      create(:challenge_story_like, user: user, challenge_story: story)

      expect(story.liked_by?(user)).to be true
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns non-completed stories" do
        active = create(:challenge_story, completed: false)
        create(:challenge_story, :completed)

        expect(ChallengeStory.active).to eq([active])
      end
    end

    describe ".completed" do
      it "returns completed stories" do
        create(:challenge_story, completed: false)
        completed = create(:challenge_story, :completed)

        expect(ChallengeStory.completed).to eq([completed])
      end
    end
  end
end
