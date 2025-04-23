class CreateChallengeComments < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_comments, id: :uuid do |t|
      t.text :comment, null: false
      t.references :challenge_participant, null: false, foreign_key: true, type: :uuid
      t.references :challenge_story, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
