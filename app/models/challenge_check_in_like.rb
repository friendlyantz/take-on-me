# frozen_string_literal: true

class ChallengeCheckInLike < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :challenge_check_in, counter_cache: true

  # Validations
  validates :user_id, uniqueness: {scope: :challenge_check_in_id}

  # Callbacks
  after_create_commit -> { broadcast_update_to challenge_check_in.challenge_story, target: "challenge_check_in_#{challenge_check_in.id}_likes", partial: "challenge_check_ins/likes", locals: {challenge_check_in: challenge_check_in} }
  after_destroy_commit -> { broadcast_update_to challenge_check_in.challenge_story, target: "challenge_check_in_#{challenge_check_in.id}_likes", partial: "challenge_check_ins/likes", locals: {challenge_check_in: challenge_check_in} }
end
