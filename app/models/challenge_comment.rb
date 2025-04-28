class ChallengeComment < ApplicationRecord
  belongs_to :challenge_participant
  belongs_to :challenge_story

  has_one_attached :photo

  validates :message, presence: true

  broadcasts_to :challenge_story, action: :prepend
  # broadcasts_to ->(challenge_story) { "challenge_stories" }, inserts_by: :prepend
  # after_create_commit -> { broadcast_append_to challenge_story }
  # after_destroy_commit -> { broadcast_remove_to challenge_story }
  # after_update_commit -> { broadcast_remove_to challenge_story }
end
