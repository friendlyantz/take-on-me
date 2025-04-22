class ChallengeParticipantsController < ApplicationController
  include ActionView::RecordIdentifier
  def create
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
    @participant = ChallengeParticipant.find_or_create_by(
      user: current_user,
      challenge_story_id: params[:challenge_story_id]
    )

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
    @challenge_participant.destroy

    respond_to do |format|
      format.html { redirect_to challenge_stories_path, notice: "You have left the challenge!" }
    end
  end
end
