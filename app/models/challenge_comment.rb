class ChallengeComment < ApplicationRecord
  belongs_to :challenge_participant
  belongs_to :challenge_story

  validates :comment, presence: true
end
