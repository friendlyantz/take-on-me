class ChallengeParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :challenge_story

  has_many :given_rewards, class_name: "ChallengeReward", foreign_key: "giver_id", dependent: :destroy
  has_many :received_rewards, class_name: "ChallengeReward", foreign_key: "receiver_id", dependent: :destroy
  has_many :challenge_comments, dependent: :nullify

  before_create :set_default_name

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  def active?
    status == "active"
  end

  def leave!
    update(status: "inactive")
  end

  def rejoin!
    update(status: "active")
  end

  private

  def set_default_name
    self.name = user.username if user.present?
  end
end
