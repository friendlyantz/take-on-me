# frozen_string_literal: true

class ChallengeParticipant < ApplicationRecord
  # Associations
  belongs_to :user, counter_cache: true
  belongs_to :challenge_story, counter_cache: true
  has_many :given_rewards, class_name: "ChallengeReward", foreign_key: "giver_id", dependent: :destroy
  has_many :received_rewards, class_name: "ChallengeReward", foreign_key: "receiver_id", dependent: :destroy
  has_many :challenge_check_ins, dependent: :nullify

  # Enums
  enum :status, %w[active inactive].index_by(&:itself)

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :inactive, -> { where(status: :inactive) }

  # Callbacks
  before_create :set_default_name

  # Public methods
  def leave!
    update!(status: :inactive)
  end

  def rejoin!
    update!(status: :active)
  end

  def has_pledged_to_all_active_participants?
    other_active_ids = challenge_story.active_participants.where.not(id: id).pluck(:id)
    return true if other_active_ids.empty?

    pledged_ids = given_rewards.pluck(:receiver_id)
    (other_active_ids - pledged_ids).empty?
  end

  def unpledged_participants
    pledged_ids = given_rewards.pluck(:receiver_id)
    challenge_story.active_participants
      .where.not(id: id)
      .where.not(id: pledged_ids)
  end

  def missing_pledges?
    !has_pledged_to_all_active_participants?
  end

  private

  def set_default_name
    self.name = user.username if user.present?
  end
end
