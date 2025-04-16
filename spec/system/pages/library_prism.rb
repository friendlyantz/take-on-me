class LibraryPrism
  def home
    Library::HomePage.new
  end

  def challenge_stories
    Library::ChallengeStoriesPage.new
  end
end
