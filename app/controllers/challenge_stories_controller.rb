class ChallengeStoriesController < ApplicationController
  before_action :set_challenge_story, only: %i[show edit update destroy complete]
  before_action :enforce_current_user, only: %i[new create edit update destroy complete]

  def index
    return @challenge_stories = ChallengeStory.none unless current_user

    @challenge_stories = ChallengeStory
      .joins(:challenge_participants)
      .where(challenge_participants: {user_id: current_user.id, status: :active})
      .merge(ChallengeStory.active)
      .left_joins(:challenge_comments)
      .group("challenge_stories.id")
      .order(Arel.sql("MAX(challenge_comments.created_at) DESC NULLS LAST, challenge_stories.updated_at DESC"))
  end

  def show
  end

  def new
    @challenge_story = ChallengeStory.new(
      start: Time.zone.today,
      finish: Time.zone.today + 7.days
    )
  end

  def edit
  end

  def create
    @challenge_story = ChallengeStory.new(challenge_story_params)

    if @challenge_story.save
      redirect_to @challenge_story, notice: "Challenge story was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @challenge_story.update(challenge_story_params)
      redirect_to @challenge_story, notice: "Challenge story was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @challenge_story.destroy!
    redirect_to challenge_stories_path, status: :see_other, notice: "Challenge story was successfully destroyed."
  end

  def complete
    @challenge_story.mark_complete!
    redirect_to challenge_stories_path, notice: "Challenge marked as complete! Time to create a new one."
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params.expect(:id))
  end

  def challenge_story_params
    params.expect(challenge_story: [:title, :description, :start, :finish])
  end

  def enforce_current_user
    redirect_to new_session_path if current_user.blank?
  end
end
