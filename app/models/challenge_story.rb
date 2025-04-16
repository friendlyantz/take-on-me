class ChallengeStory < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :description, length: {maximum: 500}
  validates :start, presence: true
  validates :finish, presence: true
  validate :finish_cannot_be_earlier_than_start

  private

  def finish_cannot_be_earlier_than_start
    if finish.present? && start.present? && finish < start
      errors.add(:finish, "cannot be earlier than the start date")
    end
  end
end
