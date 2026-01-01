# frozen_string_literal: true

class LibraryPrism
  def home
    Library::HomePage.new
  end

  def challenge_stories
    Library::ChallengeStoriesPage.new
  end

  def new_challenge_story
    Library::NewChallengeStoryPage.new
  end

  def challenge_story(record_or_id = {})
    Library::ChallengeStoryShowPage.new(record_or_id)
  end
end
