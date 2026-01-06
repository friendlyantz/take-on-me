class UpdateActiveStorageAttachmentsForCheckIns < ActiveRecord::Migration[8.0]
  def up
    # Update Active Storage attachments to reference the new model name
    ActiveStorage::Attachment.where(record_type: "ChallengeComment")
      .update_all(record_type: "ChallengeCheckIn")
  end

  def down
    # Revert Active Storage attachments to old model name
    ActiveStorage::Attachment.where(record_type: "ChallengeCheckIn")
      .update_all(record_type: "ChallengeComment")
  end
end
