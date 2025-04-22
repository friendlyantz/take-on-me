class ChallengeParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :challenge_story

  before_create :set_default_name

  private

  def set_default_name
    self.name = user.username if user.present?
  end
end
