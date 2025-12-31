class ChallengeCommentsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_current_user!
  before_action :set_challenge_story
  before_action :ensure_participant, only: [:new, :create]

  def new
    @challenge_comment = ChallengeComment.new(challenge_story_id: @challenge_story.id)
  end

  def create
    return redirect_to challenge_story_path(@challenge_story), alert: "Cannot add comments to completed challenges" if @challenge_story.completed?

    @challenge_participant = @challenge_story.find_or_activate_participant!(current_user)
    @challenge_comment = @challenge_participant.challenge_comments.build(challenge_comment_params)
    @challenge_comment.challenge_story = @challenge_story

    if @challenge_comment.save
      redirect_to @challenge_story, notice: "Comment was successfully added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def ensure_participant
    return if @challenge_story.active_participants.exists?(user: current_user)

    redirect_to challenge_story_path(@challenge_story), alert: "You must be a participant to check in"
  end

  def challenge_comment_params
    params.expect(challenge_comment: [:message, :photo])
  end
end
