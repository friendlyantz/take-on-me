class ChallengeStory < ApplicationRecord
  MAX_PARTICIPANTS = 2

  has_many :challenge_comments, dependent: :destroy
  has_many :challenge_participants, dependent: :destroy
  has_many :challenge_rewards, dependent: :destroy
  has_many :active_participants, -> { where(status: "active") }, class_name: "ChallengeParticipant"
  has_many :challenge_story_likes, dependent: :destroy
  has_many :liking_users, through: :challenge_story_likes, source: :user

  self.implicit_order_column = "created_at"

  validates :title, presence: true
  validates :description, presence: true
  validates :description, length: {maximum: 500}
  validates :start, presence: true
  validates :finish, presence: true
  validate :finish_cannot_be_earlier_than_start

  scope :active, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }

  broadcasts

  def finished?
    finish < Time.zone.today
  end

  def liked_by?(user)
    return false unless user
    challenge_story_likes.exists?(user: user)
  end

  def like_count
    challenge_story_likes.count
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

  def completed?
    completed
  end

  private

  def finish_cannot_be_earlier_than_start
    if finish.present? && start.present? && finish < start
      errors.add(:finish, "cannot be earlier than the start date")
    end
  end
end
