class CreateChallengeParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_participants, id: :uuid do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :challenge_story, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :challenge_participants, [:user_id, :challenge_story_id], unique: true
  end
end
