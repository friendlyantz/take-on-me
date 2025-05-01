class CreateChallengeRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_rewards, id: :uuid do |t|
      t.references :giver, null: false, foreign_key: {to_table: :challenge_participants}, type: :uuid
      t.references :receiver, null: false, foreign_key: {to_table: :challenge_participants}, type: :uuid
      t.references :challenge_story, null: false, foreign_key: true, type: :uuid
      t.string :description, null: false
      t.string :status, default: "pending", null: false
      t.datetime :fulfilled_at

      t.timestamps

      t.index [:giver_id, :receiver_id, :challenge_story_id], unique: true, name: "index_challenge_rewards_on_participants_and_story"
    end
  end
end
