RSpec.describe "Home Page", type: :feature do
  it "does something useful" do
    visit "/"

    expect(page).to have_content("Take On Me")
  end
end
