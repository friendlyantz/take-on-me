class ChallengeComment < ApplicationRecord
  self.implicit_order_column = "created_at"

  belongs_to :challenge_participant
  belongs_to :challenge_story

  has_one_attached :photo
  has_many :challenge_comment_likes, dependent: :destroy
  has_many :liking_users, through: :challenge_comment_likes, source: :user

  validates :message, presence: true

  broadcasts_to :challenge_story, action: :prepend
  default_scope { order(created_at: :asc) } # Oldest first

  def liked_by?(user)
    return false unless user
    challenge_comment_likes.exists?(user: user)
  end

  def like_count
    challenge_comment_likes.count
  end
end
