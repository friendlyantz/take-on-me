class CreateChallengeStoryLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_story_likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :challenge_story, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :challenge_story_likes, [:user_id, :challenge_story_id], unique: true, name: "index_challenge_story_likes_on_user_and_story"
  end
end
