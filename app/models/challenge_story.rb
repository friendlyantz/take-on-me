class ChallengeStory < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :description, length: {maximum: 500}
  validates :start, presence: true
  validates :finish, presence: true
end
