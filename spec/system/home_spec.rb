require "system_helper"

RSpec.describe "Home Page", type: :system do
  let(:home) { prism.library.home }

  scenario "I can start a challange and keep progress" do
    home.load

    home.new_challenge.click
    expect(page).to have_content("Start a new challenge")
    expect(page).to have_content("Title")
    expect(page).to have_content("Description")
    expect(page).to have_content("Start")
    expect(page).to have_content("Finish")

    new_challenge_form = prism.library.challenge_stories
    # TODO: narrow down pareprism
    new_challenge_form.challenge_title.set("My Challenge")
    new_challenge_form.description.set("This is a description of my challenge.")
    new_challenge_form.start.set(Time.zone.today)
    new_challenge_form.finish.set(Time.zone.today - 8.days)
    new_challenge_form.submit.click
    expect(page).to have_content("Finish cannot be earlier than the start date")

    new_challenge_form.finish.set(Time.zone.today + 8.days)
    new_challenge_form.submit.click
    expect(page).to have_content("Challenge story was successfully created.")
    # debug(binding)
  end
end
