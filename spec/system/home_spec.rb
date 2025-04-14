require "system_helper"

RSpec.describe "Home Page", type: :system do
  scenario "I can start a challange and keep progress" do
    prism.home.load

    # debug(binding)
    pending
    @home.new_challange.click
  end
end
