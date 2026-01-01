class HomeController < ApplicationController
  layout "hero"

  def index
    return unless current_user

    latest = current_user.latest_active_participation
    redirect_to latest ? challenge_story_path(latest.challenge_story) : challenge_stories_path
  end
end
