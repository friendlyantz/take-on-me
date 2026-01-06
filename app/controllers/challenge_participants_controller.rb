class ChallengeParticipantsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_current_user!
  before_action :set_challenge_story, only: [:create]

  def create
    return redirect_to challenge_story_path(@challenge_story), alert: "This challenge is full (max #{ChallengeStory::MAX_PARTICIPANTS} participants)" if @challenge_story.at_capacity?

    @current_challenge_participant = @challenge_story.find_or_activate_participant!(current_user)

    respond_to do |format|
      format.turbo_stream do
        @challenge_check_in = ChallengeCheckIn.new(challenge_story_id: @challenge_story.id)
        render turbo_stream: [

          turbo_stream.replace(
            "story-#{@challenge_story.id}-joining_participant",
            partial: "challenge_participants/participant_joined_alert",
            locals: {current_challenge_participant: @current_challenge_participant}
          ),
          turbo_stream.replace(
            "new_message",
            partial: "challenge_check_ins/form",
            locals: {challenge_story: @challenge_story, challenge_check_in: @challenge_check_in}
          )
        ]
      end
      format.html { redirect_to challenge_story_path(@challenge_story), notice: "You have joined the challenge!" }
    end
  end

  def destroy
    challenge_participant = ChallengeParticipant.find(params[:id])
    challenge_participant.leave!
    redirect_to challenge_story_path(challenge_participant.challenge_story), notice: "You have left the challenge!"
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end
end
