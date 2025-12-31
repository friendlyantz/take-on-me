class ChallengeStoriesController < ApplicationController
  before_action :set_challenge_story, only: %i[edit update destroy complete]
  before_action :require_current_user!, except: %i[show]

  def index
    return @challenge_stories = ChallengeStory.none unless current_user

    @challenge_stories = ChallengeStory
      .joins(:challenge_participants)
      .where(challenge_participants: {user_id: current_user.id, status: :active})
      .includes(challenge_comments: {photo_attachment: :blob})
      .left_joins(:challenge_comments)
      .group("challenge_stories.id")
      .order(Arel.sql("MAX(challenge_comments.created_at) DESC NULLS LAST, challenge_stories.updated_at DESC"))
  end

  def show
    @challenge_story = ChallengeStory
      .includes(
        challenge_participants: :user,
        challenge_rewards: [:giver, :receiver],
        challenge_comments: [:challenge_participant, :challenge_comment_likes, photo_attachment: :blob]
      )
      .find(params[:id])
    @current_participant = @challenge_story.challenge_participants.find_by(user: current_user) if current_user
    @today_comment = @current_participant&.challenge_comments&.find_by(created_at: Time.zone.today.all_day)
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
      @challenge_story.find_or_activate_participant!(current_user)
      redirect_to @challenge_story, notice: "Challenge story was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @challenge_story.update(challenge_story_params)
      redirect_to @challenge_story, notice: "Challenge story was successfully updated."
    else
      render :edit, status: :unprocessable_content
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
end
