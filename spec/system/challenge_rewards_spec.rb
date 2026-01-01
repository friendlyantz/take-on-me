require "system_helper"

RSpec.describe "Challenge Rewards", type: :system do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge_story) }
  let!(:giver) { create(:challenge_participant, user: user, challenge_story: challenge) }
  let!(:receiver) { create(:challenge_participant, challenge_story: challenge) }

  before do
    sign_in_as(user)
  end

  describe "pledging rewards" do
    scenario "participant can pledge a reward to another participant" do
      visit challenge_story_challenge_rewards_path(challenge)

      click_on "Pledge a New Reward"

      select receiver.name, from: "Who gets the reward?"
      fill_in "What will you give them?", with: "I'll buy you coffee if you complete the challenge!"
      click_on "Pledge Reward"

      expect(page).to have_content("I'll buy you coffee")
    end
  end

  describe "viewing rewards" do
    let!(:reward) do
      create(:challenge_reward,
        giver: giver,
        receiver: receiver,
        challenge_story: challenge,
        description: "Coffee reward")
    end

    scenario "participant can see rewards they've pledged" do
      visit challenge_story_challenge_rewards_path(challenge)

      expect(page).to have_content("Rewards You've Pledged")
      expect(page).to have_content("Coffee reward")
    end
  end

  describe "canceling rewards" do
    let(:finished_challenge) { create(:challenge_story, :finished) }
    let!(:finished_giver) { create(:challenge_participant, user: user, challenge_story: finished_challenge) }
    let!(:finished_receiver) { create(:challenge_participant, challenge_story: finished_challenge) }
    let!(:reward) do
      create(:challenge_reward,
        giver: finished_giver,
        receiver: finished_receiver,
        challenge_story: finished_challenge,
        status: "pending")
    end

    scenario "giver can cancel their reward after challenge finishes" do
      visit challenge_story_challenge_rewards_path(finished_challenge)

      accept_confirm do
        click_on "Cancel"
      end

      expect(page).to have_content("Canceled")
    end
  end
end
