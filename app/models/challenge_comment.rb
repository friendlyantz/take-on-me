class ChallengeComment < ApplicationRecord
  belongs_to :challenge_participant
  belongs_to :challenge_story

  validates :message, presence: true
end
