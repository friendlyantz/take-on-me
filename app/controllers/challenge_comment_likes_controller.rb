class ChallengeCommentLikesController < ApplicationController
  before_action :enforce_current_user
  before_action :set_challenge_comment

  def create
    @like = @challenge_comment.challenge_comment_likes.build(user: current_user)

    respond_to do |format|
      if @like.save
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_comment.challenge_story), notice: "You liked this comment.") }
        format.turbo_stream
      else
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_comment.challenge_story), alert: "Something went wrong.") }
      end
    end
  end

  def destroy
    @like = @challenge_comment.challenge_comment_likes.find_by(user: current_user)

    if @like
      @like.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: challenge_story_path(@challenge_comment.challenge_story), notice: "You unliked this comment.") }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: challenge_story_path(@challenge_comment.challenge_story))
    end
  end

  private

  def set_challenge_comment
    @challenge_comment = ChallengeComment.find(params[:challenge_comment_id])
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end
end
