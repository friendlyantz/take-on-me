# frozen_string_literal: true

class Library::ChallengeStoriesPage < BasePage
  set_url "/challenge_stories"

  element :page_heading, "h1"
  elements :challenge_cards, ".card"

  load_validation { has_page_heading? }

  def has_challenge?(title)
    has_text?(title)
  end
end
