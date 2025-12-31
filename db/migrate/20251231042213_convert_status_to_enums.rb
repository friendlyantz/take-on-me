class ConvertStatusToEnums < ActiveRecord::Migration[8.0]
  def up
    # Create enum types
    create_enum :challenge_reward_status, ["pending", "fulfilled", "canceled"]
    create_enum :challenge_participant_status, ["active", "inactive"]

    # Add new enum columns
    add_column :challenge_rewards, :status_enum, :enum, enum_type: :challenge_reward_status, default: "pending", null: false
    add_column :challenge_participants, :status_enum, :enum, enum_type: :challenge_participant_status, default: "active", null: false

    # Copy data from string to enum
    ChallengeReward.reset_column_information
    ChallengeReward.find_each do |reward|
      reward.update_column(:status_enum, reward.status)
    end

    ChallengeParticipant.reset_column_information
    ChallengeParticipant.find_each do |participant|
      participant.update_column(:status_enum, participant.status)
    end

    # Remove old string columns
    remove_column :challenge_rewards, :status
    remove_column :challenge_participants, :status

    # Rename enum columns to status
    rename_column :challenge_rewards, :status_enum, :status
    rename_column :challenge_participants, :status_enum, :status
  end

  def down
    # Reverse the process
    rename_column :challenge_rewards, :status, :status_enum
    rename_column :challenge_participants, :status, :status_enum

    add_column :challenge_rewards, :status, :string, default: "pending"
    add_column :challenge_participants, :status, :string, default: "active"

    ChallengeReward.reset_column_information
    ChallengeReward.find_each do |reward|
      reward.update_column(:status, reward.status_enum)
    end

    ChallengeParticipant.reset_column_information
    ChallengeParticipant.find_each do |participant|
      participant.update_column(:status, participant.status_enum)
    end

    remove_column :challenge_rewards, :status_enum
    remove_column :challenge_participants, :status_enum

    drop_enum :challenge_participant_status
    drop_enum :challenge_reward_status
  end
end
