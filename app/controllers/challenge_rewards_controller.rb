class ChallengeRewardsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :enforce_current_user
  before_action :set_challenge_story
  before_action :set_reward, only: [:fulfill, :cancel]
  before_action :verify_receiver, only: [:fulfill]
  before_action :verify_giver, only: [:cancel]

  def index
    return @rewards_received = @rewards_given = @rewards_others = [] unless current_user

    current_participant = @challenge_story.challenge_participants.find_by(user: current_user)
    return @rewards_received = @rewards_given = @rewards_others = [] unless current_participant

    all_rewards = @challenge_story.challenge_rewards.includes(giver: :user, receiver: :user)

    @rewards_received = all_rewards.where(receiver: current_participant)
    @rewards_given = all_rewards.where(giver: current_participant)
    @rewards_others = all_rewards.where.not(id: @rewards_received.pluck(:id) + @rewards_given.pluck(:id))
  end

  def new
    @reward = ChallengeReward.new(challenge_story: @challenge_story)
    @current_participant = current_participant_for_story
    @participants = available_participants_for_pledge
  end

  def create
    @reward = ChallengeReward.new(reward_params)
    @reward.challenge_story = @challenge_story

    if @reward.save
      redirect_to challenge_story_challenge_rewards_path(@challenge_story),
        notice: "You've successfully pledged a reward!"
    else
      @current_participant = current_participant_for_story
      @participants = available_participants_for_pledge
      render :new, status: :unprocessable_content
    end
  end

  def fulfill
    @reward.fulfill!
    redirect_to challenge_story_challenge_rewards_path(@challenge_story),
      notice: "Reward has been marked as fulfilled!"
  end

  def cancel
    @reward.cancel!
    redirect_to challenge_story_challenge_rewards_path(@challenge_story),
      notice: "Reward has been canceled."
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params[:challenge_story_id])
  end

  def set_reward
    @reward = @challenge_story.challenge_rewards.find(params[:id])
  end

  def verify_giver
    return if @reward.giver.user == current_user

    redirect_to challenge_story_challenge_rewards_path(@challenge_story),
      alert: "You can only cancel rewards you've pledged."
  end

  def verify_receiver
    return if @reward.receiver.user == current_user

    redirect_to challenge_story_challenge_rewards_path(@challenge_story),
      alert: "You can only fulfill rewards pledged to you."
  end

  def reward_params
    params.require(:challenge_reward).permit(:giver_id, :receiver_id, :description)
  end

  def enforce_current_user
    redirect_to new_session_path if current_user.blank?
  end

  def current_participant_for_story
    @challenge_story.active_participants.find_by(user: current_user)
  end

  def available_participants_for_pledge
    current_participant = current_participant_for_story
    return [] unless current_participant

    existing_receiver_ids = ChallengeReward.where(
      giver_id: current_participant.id,
      challenge_story_id: @challenge_story.id
    ).pluck(:receiver_id)

    @challenge_story.active_participants.where.not(id: existing_receiver_ids)
  end
end
