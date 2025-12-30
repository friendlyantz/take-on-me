class ChallengeReward < ApplicationRecord
  belongs_to :giver, class_name: "ChallengeParticipant"
  belongs_to :receiver, class_name: "ChallengeParticipant"
  belongs_to :challenge_story

  validates :description, presence: true
  validates :status, inclusion: {in: %w[pending fulfilled canceled]}
  validates :giver_id, uniqueness: {scope: [:receiver_id, :challenge_story_id], message: "has already pledged a reward to this participant"}
  validate :cannot_reward_self
  validate :participants_in_same_challenge

  scope :pending, -> { where(status: "pending") }
  scope :fulfilled, -> { where(status: "fulfilled") }
  scope :canceled, -> { where(status: "canceled") }

  def fulfill!
    update(status: "fulfilled", fulfilled_at: Time.current)
  end

  def cancel!
    update(status: "canceled")
  end

  private

  def cannot_reward_self
    errors.add(:receiver_id, "can't be the same as giver") if giver_id == receiver_id
  end

  def participants_in_same_challenge
    return unless giver && receiver

    unless giver.challenge_story_id == receiver.challenge_story_id
      errors.add(:base, "Both participants must be in the same challenge")
    end
  end
end
