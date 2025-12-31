class ChallengeParticipantsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :enforce_current_user
  before_action :set_challenge_story

  def create
    return redirect_to challenge_story_path(@challenge_story), alert: "This challenge is full (max #{ChallengeStory::MAX_PARTICIPANTS} participants)" if @challenge_story.at_capacity?

    @participant = @challenge_story.find_or_activate_participant!(current_user)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "story-#{@challenge_story.id}-joining_participant",
          partial: "challenge_participants/participant_details",
          locals: {participant: @participant}
        )
      end
      format.html { redirect_to challenge_story_path(@challenge_story), notice: "You have joined the challenge!" }
    end
  end

  def destroy
    @challenge_participant = ChallengeParticipant.find(params[:id])
    @challenge_participant.leave!
    redirect_to challenge_stories_path, notice: "You have left the challenge!"
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def enforce_current_user
    redirect_to new_session_path if current_user.blank?
  end
end
