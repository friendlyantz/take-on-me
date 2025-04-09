RSpec.describe "Home Page", type: :feature do
  it "has navbar" do
    @home = Home.new
    @home.load

    expect(@home).to have_navbar
    expect(@home.navbar).to have_content("Take On Me")
  end
end
