# frozen_string_literal: true

class ChallengeStoryLike < ApplicationRecord
  # Associations
  belongs_to :user, counter_cache: true
  belongs_to :challenge_story, counter_cache: true

  # Validations
  validates :user_id, uniqueness: {scope: :challenge_story_id}

  # Callbacks
  after_create_commit -> { broadcast_update_to challenge_story, target: "challenge_story_#{challenge_story.id}_likes", partial: "challenge_stories/likes", locals: {challenge_story: challenge_story} }
  after_destroy_commit -> { broadcast_update_to challenge_story, target: "challenge_story_#{challenge_story.id}_likes", partial: "challenge_stories/likes", locals: {challenge_story: challenge_story} }
end
