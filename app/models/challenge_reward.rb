class ChallengeReward < ApplicationRecord
  # Associations
  belongs_to :giver, class_name: "ChallengeParticipant", counter_cache: :given_rewards_count
  belongs_to :receiver, class_name: "ChallengeParticipant", counter_cache: :received_rewards_count
  belongs_to :challenge_story, counter_cache: true

  # Enums
  enum :status, %w[pending fulfilled canceled].index_by(&:itself)

  # Validations
  validates :description, presence: true
  validates :giver_id, uniqueness: {scope: [:receiver_id, :challenge_story_id], message: "has already pledged a reward to this participant"}
  validate :cannot_reward_self
  validate :participants_in_same_challenge

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :fulfilled, -> { where(status: :fulfilled) }
  scope :canceled, -> { where(status: :canceled) }

  # Public methods
  def fulfill!
    update!(status: :fulfilled, fulfilled_at: Time.current)
  end

  def cancel!
    update!(status: :canceled)
  end

  private

  def cannot_reward_self
    errors.add(:receiver_id, "can't be the same as giver") if giver_id == receiver_id
  end

  def participants_in_same_challenge
    return unless giver && receiver
    return if giver.challenge_story_id == receiver.challenge_story_id

    errors.add(:base, "Both participants must be in the same challenge")
  end
end
