class ChallengeStory < ApplicationRecord
  MAX_PARTICIPANTS = 2

  # Associations
  has_many :challenge_comments, dependent: :destroy, counter_cache: true
  has_many :challenge_participants, dependent: :destroy, counter_cache: true
  has_many :challenge_rewards, dependent: :destroy, counter_cache: true
  has_many :challenge_story_likes, dependent: :destroy, counter_cache: true
  has_many :active_participants, -> { where(status: "active") }, class_name: "ChallengeParticipant"
  has_many :liking_users, through: :challenge_story_likes, source: :user

  # DSL extensions
  self.implicit_order_column = "created_at"
  broadcasts

  # Validations
  validates :title, presence: true
  validates :description, presence: true, length: {maximum: 500}
  validates :start, :finish, presence: true
  validate :finish_cannot_be_earlier_than_start

  # Scopes
  scope :active, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }

  # Public methods
  def finished?
    finish < Time.zone.today
  end

  def liked_by?(user)
    return false unless user
    challenge_story_likes.exists?(user: user)
  end

  def at_capacity?
    active_participants.count >= MAX_PARTICIPANTS
  end

  def available_spots
    MAX_PARTICIPANTS - active_participants.count
  end

  def mark_complete!
    update!(completed: true)
  end

  private

  def finish_cannot_be_earlier_than_start
    if finish.present? && start.present? && finish < start
      errors.add(:finish, "cannot be earlier than the start date")
    end
  end
end
