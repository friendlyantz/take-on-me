class HomePage < SitePrism::Page
  set_url "/home/index.htm"
  element :navbar, "#navbar"
  element :menu, "#menu"
  element :new_challenge, "#new-challenge"

  load_validation { has_navbar? && navbar.has_text?("Take On Me") }
end
