class ChallengeCommentsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :enforce_current_user
  def new
    @challenge_comment = ChallengeComment.new(challenge_story_id: params[:challenge_story_id])
  end

  def create
    @challenge_comment = ChallengeComment.new(challenge_comment_params)
    challenge_story = ChallengeStory.find(params[:challenge_story_id])
    challenge_participant = ChallengeParticipant.find_or_create_by(user: current_user, challenge_story: challenge_story)
    @challenge_comment.challenge_participant = challenge_participant
    @challenge_comment.challenge_story = challenge_story

    respond_to do |format|
      if @challenge_comment.save
        format.html { redirect_to challenge_story, notice: "Comment was successfully added." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_message",
            template: "challenge_comments/new",

            locals: {challenge_comment: @challenge_comment},
            status: :unprocessable_entity
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  private

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end

  def challenge_comment_params
    params.expect(challenge_comment: [:message])
  end
end
