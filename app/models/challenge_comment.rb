class ChallengeComment < ApplicationRecord
  self.implicit_order_column = "created_at"
  default_scope { order(created_at: :asc) }

  belongs_to :challenge_participant, counter_cache: true
  belongs_to :challenge_story, counter_cache: true
  has_one_attached :photo
  has_many :challenge_comment_likes, dependent: :destroy
  has_many :liking_users, through: :challenge_comment_likes, source: :user

  validates :message, presence: true
  validate :one_comment_per_day_per_participant

  # Broadcasts (after attachments, as it is callback anti-pattern)
  broadcasts_to :challenge_story, action: :prepend

  # Public methods
  def liked_by?(user)
    return false unless user
    challenge_comment_likes.exists?(user: user)
  end

  private

  def one_comment_per_day_per_participant
    return if challenge_participant.blank?

    existing_comment_today = ChallengeComment.unscoped.exists?(
      challenge_participant_id: challenge_participant_id,
      created_at: Time.zone.today.all_day
    )

    if existing_comment_today && new_record?
      errors.add(:base, "You can only check in once per day")
    end
  end
end
