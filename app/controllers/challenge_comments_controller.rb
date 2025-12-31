class ChallengeCommentsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :enforce_current_user
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

    respond_to do |format|
      if @challenge_comment.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("challenge_comments", partial: "challenge_comments/challenge_comment", locals: {challenge_comment: @challenge_comment}),
            turbo_stream.replace("new_message",
              template: "challenge_comments/new",
              locals: {challenge_comment: ChallengeComment.new(challenge_story_id: @challenge_story.id)})
          ]
        end
        format.html { redirect_to @challenge_story, notice: "Comment was successfully added." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_message",
            template: "challenge_comments/new",

            locals: {challenge_comment: @challenge_comment},
            status: :unprocessable_entity
          )
        end
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def destroy
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def enforce_current_user
    redirect_to new_session_path if current_user.blank?
  end

  def ensure_participant
    unless @challenge_story.active_participants.exists?(user: current_user)
      redirect_to challenge_story_path(@challenge_story), alert: "You must be a participant to check in"
    end
  end

  def challenge_comment_params
    params.expect(challenge_comment: [:message, :photo])
  end
end
