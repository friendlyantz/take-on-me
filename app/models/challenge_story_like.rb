class ChallengeStoryLike < ApplicationRecord
  belongs_to :user
  belongs_to :challenge_story

  validates :user_id, uniqueness: {scope: :challenge_story_id}

  after_create_commit -> { broadcast_update_to challenge_story, target: "challenge_story_#{challenge_story.id}_likes", partial: "challenge_stories/likes", locals: {challenge_story: challenge_story} }
  after_destroy_commit -> { broadcast_update_to challenge_story, target: "challenge_story_#{challenge_story.id}_likes", partial: "challenge_stories/likes", locals: {challenge_story: challenge_story} }
end
