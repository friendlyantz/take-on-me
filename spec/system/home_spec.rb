require "system_helper"

RSpec.describe "Home Page", type: :system do
  let(:home) { prism.home }

  scenario "I can start a challange and keep progress" do
    home.load

    home.new_challenge.click
    expect(page).to have_content("Start a new challenge")
    expect(page).to have_content("Title")
    expect(page).to have_content("Description")
    expect(page).to have_content("Start")
    expect(page).to have_content("Finish")

    pending
    # debug(binding)
    new_challenge_form = prism.challenge_stories.new_challenge_form
    new_challenge_form.title.set("My Challenge")
    new_challenge_form.description.set("This is a description of my challenge.")
    new_challenge_form.start.set(Time.zone.today)
    new_challenge_form.finish.set(Time.zone.today - 8.days)
    new_challenge_form.submit.click
    expect(page).to have_content("Date must be after or equal to today")
  end
end
