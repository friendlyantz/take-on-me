class ChallengeCheckInLikesController < ApplicationController
  before_action :require_current_user!
  before_action :set_challenge_check_in

  def create
    @like = @challenge_check_in.challenge_check_in_likes.build(user: current_user)

    if @like.save
      respond_to do |format|
        format.html { redirect_back_or_to(challenge_story_path(@challenge_check_in.challenge_story), notice: "You liked this check-in.") }
        format.turbo_stream
      end
    else
      redirect_back_or_to(challenge_story_path(@challenge_check_in.challenge_story), alert: "Something went wrong.")
    end
  end

  def destroy
    @like = @challenge_check_in.challenge_check_in_likes.find_by(user: current_user)
    return redirect_back_or_to(challenge_story_path(@challenge_check_in.challenge_story)) unless @like

    @like.destroy
    respond_to do |format|
      format.html { redirect_back_or_to(challenge_story_path(@challenge_check_in.challenge_story), notice: "You unliked this check-in.") }
      format.turbo_stream
    end
  end

  private

  def set_challenge_check_in
    @challenge_check_in = ChallengeCheckIn.find(params[:challenge_check_in_id])
  end
end
