class ChallengeParticipantsController < ApplicationController
  include ActionView::RecordIdentifier

  def create
    if current_user.nil?
      return redirect_to new_session_path
    end

    @challenge_story = ChallengeStory.find(params[:challenge_story_id])

    # Try to find an existing participant (active or inactive)
    @participant = ChallengeParticipant.find_by(
      user: current_user,
      challenge_story_id: params[:challenge_story_id]
    )

    if @participant
      # If the participant exists but is inactive, reactivate them
      @participant.update(status: "active") if @participant.status == "inactive"
    else
      # Create a new participant if none exists
      @participant = ChallengeParticipant.create(
        user: current_user,
        challenge_story_id: params[:challenge_story_id]
      )
    end

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

    respond_to do |format|
      format.html { redirect_to challenge_stories_path, notice: "You have left the challenge!" }
    end
  end
end
