class ChallengeCommentLike < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :challenge_comment, counter_cache: true

  # Validations
  validates :user_id, uniqueness: {scope: :challenge_comment_id}

  # Callbacks
  after_create_commit -> { broadcast_update_to challenge_comment.challenge_story, target: "challenge_comment_#{challenge_comment.id}_likes", partial: "challenge_comments/likes", locals: {challenge_comment: challenge_comment} }
  after_destroy_commit -> { broadcast_update_to challenge_comment.challenge_story, target: "challenge_comment_#{challenge_comment.id}_likes", partial: "challenge_comments/likes", locals: {challenge_comment: challenge_comment} }
end
