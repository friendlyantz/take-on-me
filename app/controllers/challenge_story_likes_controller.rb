class ChallengeStoryLikesController < ApplicationController
  before_action :enforce_current_user
  before_action :set_challenge_story

  def create
    @like = @challenge_story.challenge_story_likes.build(user: current_user)

    respond_to do |format|
      if @like.save
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_story), notice: "You liked this challenge.") }
        format.turbo_stream
      else
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_story), alert: "Something went wrong.") }
      end
    end
  end

  def destroy
    @like = @challenge_story.challenge_story_likes.find_by(user: current_user)
    if @like
      @like.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_story), notice: "You unliked this challenge.") }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: challenge_story_path(@challenge_story))
    end
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end
end
