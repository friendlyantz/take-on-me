class Library::ChallengeStoriesPage < SitePrism::Page
  set_url "/challenges/*"

  element :challenge_title, "#challenge-title"
  element :description, "#description"
  element :start, "#start"
  element :finish, "#finish"

  element :submit, "#submit"
end
