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

  private

  def set_default_name
    self.name = user.username if user.present?
  end
end
