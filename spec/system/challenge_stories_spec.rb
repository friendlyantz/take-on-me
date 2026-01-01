require "system_helper"

RSpec.describe "Challenge Stories", type: :system do
  let(:user) { create(:user) }
  let(:new_challenge_page) { prism.library.new_challenge_story }

  describe "creating a challenge" do
    before do
      sign_in_as(user)
    end

    scenario "user creates a new challenge successfully" do
      new_challenge_page.load

      expect(page).to have_content("Start a New Challenge")

      new_challenge_page.fill_form(
        title: "30 Day Fitness Challenge",
        description: "Exercise every day for 30 days",
        start_date: Time.zone.today,
        finish_date: Time.zone.today + 30.days
      )
      new_challenge_page.submit

      # Verify we're on the show page with the new challenge
      expect(page).to have_content("30 Day Fitness Challenge")
      expect(page).to have_content("Exercise every day for 30 days")
    end

    scenario "user sees validation error for invalid dates" do
      new_challenge_page.load

      new_challenge_page.fill_form(
        title: "Invalid Challenge",
        description: "This should fail",
        start_date: Time.zone.today,
        finish_date: Time.zone.today - 1.day
      )
      new_challenge_page.submit

      expect(page).to have_content("Finish cannot be earlier than the start date")
    end
  end

  describe "viewing a challenge" do
    let!(:challenge) { create(:challenge_story, title: "Test Challenge") }
    let(:show_page) { prism.library.challenge_story(challenge) }

    before do
      sign_in_as(user)
    end

    scenario "user can view challenge details" do
      show_page.load

      expect(show_page).to be_displayed
      expect(page).to have_content("Test Challenge")
    end

    scenario "user can join a challenge" do
      show_page.load

      expect(show_page).to have_join_button

      show_page.join_button.click

      expect(page).to have_content("You've joined!")
    end
  end

  describe "challenge list" do
    let(:list_page) { prism.library.challenge_stories }

    before do
      create(:challenge_participant, user: user)
      sign_in_as(user)
    end

    scenario "user sees their active challenges" do
      list_page.load

      expect(page).to have_content("Challenges")
      expect(list_page).to have_challenge_cards
    end
  end
end
