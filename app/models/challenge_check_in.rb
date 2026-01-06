# frozen_string_literal: true

class ChallengeCheckIn < ApplicationRecord
  # Associations
  belongs_to :challenge_participant, counter_cache: true
  belongs_to :challenge_story, counter_cache: true
  has_one_attached :photo
  has_many :challenge_check_in_likes, dependent: :destroy
  has_many :liking_users, through: :challenge_check_in_likes, source: :user

  # Validations
  validates :message, presence: true
  validate :photo_size_validation
  validate :one_check_in_per_day_per_participant

  # Callbacks (broadcasts_to must be after has_one_attached for Cloudinary compatibility)
  broadcasts_to ->(check_in) { [check_in.challenge_story, "challenge_check_ins"] }, action: :prepend

  # Public methods
  def liked_by?(user)
    return false unless user
    challenge_check_in_likes.exists?(user: user)
  end

  private

  def photo_size_validation
    if photo.present? && photo.blob.byte_size > 10.megabytes
      errors.add(:photo, "is too large (maximum 10MB)")
    end
  end

  def one_check_in_per_day_per_participant
    return if challenge_participant.blank?

    existing_check_in_today = ChallengeCheckIn.unscoped.exists?(
      challenge_participant_id: challenge_participant_id,
      created_at: Time.zone.today.all_day
    )

    if existing_check_in_today && new_record?
      errors.add(:base, "You can only check in once per day")
    end
  end
end
