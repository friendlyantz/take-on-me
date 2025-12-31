class ChallengeRewardsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :enforce_current_user
  before_action :set_challenge_story
  before_action :set_reward, only: [:fulfill, :cancel]
  before_action :verify_receiver, only: [:fulfill]
  before_action :verify_giver, only: [:cancel]

  def index
    @rewards = @challenge_story.challenge_rewards
  end

  def new
    @reward = ChallengeReward.new(challenge_story: @challenge_story)
    @current_participant = @challenge_story.active_participants.find_by(user: current_user)

    # Exclude participants who already have a pledge from current user
    existing_receiver_ids = ChallengeReward.where(
      giver_id: @current_participant&.id,
      challenge_story_id: @challenge_story.id
    ).pluck(:receiver_id)

    @participants = @challenge_story.active_participants.where.not(id: existing_receiver_ids)
  end

  def create
    @reward = ChallengeReward.new(reward_params)
    @reward.challenge_story = @challenge_story

    if @reward.save
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        notice: "You've successfully pledged a reward!"
    else
      @current_participant = @challenge_story.active_participants.find_by(user: current_user)

      # Exclude participants who already have a pledge from current user
      existing_receiver_ids = ChallengeReward.where(
        giver_id: @current_participant&.id,
        challenge_story_id: @challenge_story.id
      ).pluck(:receiver_id)

      @participants = @challenge_story.active_participants.where.not(id: existing_receiver_ids)
      render :new, status: :unprocessable_entity
    end
  end

  def fulfill
    if @reward.fulfill!
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        notice: "Reward has been marked as fulfilled!"
    else
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        alert: "Could not fulfill the reward."
    end
  end

  def cancel
    if @reward.cancel!
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        notice: "Reward has been canceled."
    else
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        alert: "Could not cancel the reward."
    end
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def set_reward
    @reward = @challenge_story.challenge_rewards.find(params[:id])
  end

  def verify_giver
    unless @reward.giver.user == current_user
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        alert: "You can only cancel rewards you've pledged."
    end
  end

  def verify_receiver
    unless @reward.receiver.user == current_user
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        alert: "You can only fulfill rewards pledged to you."
    end
  end

  def reward_params
    params.require(:challenge_reward).permit(:giver_id, :receiver_id, :description)
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end
end
