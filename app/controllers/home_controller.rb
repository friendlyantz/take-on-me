class HomeController < ApplicationController
  layout "hero"

  def index
    return unless current_user

    # Redirect logged-in users to their most recent active challenge
    latest_participation = current_user.challenge_participants
      .active
      .joins(:challenge_story)
      .order("challenge_stories.updated_at DESC")
      .first

    if latest_participation
      redirect_to challenge_story_path(latest_participation.challenge_story)
    else
      redirect_to challenge_stories_path
    end
  end
end
