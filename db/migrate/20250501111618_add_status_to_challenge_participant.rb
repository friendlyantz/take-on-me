class AddStatusToChallengeParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :challenge_participants, :status, :string, default: "active", null: false
    add_index :challenge_participants, :status
  end
end
