# frozen_string_literal: true

class Library::HomePage < BasePage
  set_url "/"

  element :navbar, ".navbar"
  element :new_challenge, 'a[href="/challenge_stories/new"]'
  element :sign_in_link, 'a[href="/session/new"]'
  element :hero_title, "h1"

  # Load validation ensures page is fully loaded before proceeding
  load_validation { has_navbar?(wait: 2) }

  def signed_in?
    !has_sign_in_link?(wait: 0.5)
  end
end
