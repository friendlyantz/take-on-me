class CreateChallengeCommentLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_comment_likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :challenge_comment, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :challenge_comment_likes, [:user_id, :challenge_comment_id], unique: true, name: "index_comment_likes_on_user_and_comment"
  end
end
