class AddDatabaseConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add on_delete cascade to foreign keys
    remove_foreign_key :challenge_comment_likes, :challenge_comments
    add_foreign_key :challenge_comment_likes, :challenge_comments, on_delete: :cascade

    remove_foreign_key :challenge_comment_likes, :users
    add_foreign_key :challenge_comment_likes, :users, on_delete: :cascade

    remove_foreign_key :challenge_comments, :challenge_participants
    add_foreign_key :challenge_comments, :challenge_participants, on_delete: :cascade

    remove_foreign_key :challenge_comments, :challenge_stories
    add_foreign_key :challenge_comments, :challenge_stories, on_delete: :cascade

    remove_foreign_key :challenge_participants, :challenge_stories
    add_foreign_key :challenge_participants, :challenge_stories, on_delete: :cascade

    remove_foreign_key :challenge_participants, :users
    add_foreign_key :challenge_participants, :users, on_delete: :cascade

    remove_foreign_key :challenge_rewards, column: :giver_id
    add_foreign_key :challenge_rewards, :challenge_participants, column: :giver_id, on_delete: :cascade

    remove_foreign_key :challenge_rewards, column: :receiver_id
    add_foreign_key :challenge_rewards, :challenge_participants, column: :receiver_id, on_delete: :cascade

    remove_foreign_key :challenge_rewards, :challenge_stories
    add_foreign_key :challenge_rewards, :challenge_stories, on_delete: :cascade

    remove_foreign_key :challenge_story_likes, :challenge_stories
    add_foreign_key :challenge_story_likes, :challenge_stories, on_delete: :cascade

    remove_foreign_key :challenge_story_likes, :users
    add_foreign_key :challenge_story_likes, :users, on_delete: :cascade

    remove_foreign_key :credentials, :users
    add_foreign_key :credentials, :users, on_delete: :cascade

    # Add check constraints
    add_check_constraint :challenge_stories, "finish >= start", name: "check_finish_after_start"
    add_check_constraint :challenge_stories, "char_length(description) <= 500", name: "check_description_length"
    add_check_constraint :challenge_participants, "given_rewards_count >= 0", name: "check_given_rewards_non_negative"
    add_check_constraint :challenge_participants, "received_rewards_count >= 0", name: "check_received_rewards_non_negative"
    add_check_constraint :challenge_participants, "challenge_comments_count >= 0", name: "check_comments_count_non_negative"
    add_check_constraint :challenge_stories, "challenge_story_likes_count >= 0", name: "check_story_likes_non_negative"
    add_check_constraint :challenge_stories, "challenge_comments_count >= 0", name: "check_story_comments_non_negative"
    add_check_constraint :challenge_stories, "challenge_participants_count >= 0", name: "check_participants_non_negative"
    add_check_constraint :challenge_stories, "challenge_rewards_count >= 0", name: "check_rewards_non_negative"
    add_check_constraint :challenge_comments, "challenge_comment_likes_count >= 0", name: "check_comment_likes_non_negative"
    add_check_constraint :users, "challenge_participants_count >= 0", name: "check_user_participants_non_negative"
    add_check_constraint :users, "challenge_story_likes_count >= 0", name: "check_user_likes_non_negative"

    # Add indexes for frequently queried columns
    add_index :challenge_stories, :completed
    add_index :challenge_stories, :start
    add_index :challenge_stories, :finish
    add_index :challenge_stories, :created_at
    add_index :challenge_comments, :created_at
    add_index :challenge_participants, :status
    add_index :challenge_rewards, :status
    add_index :challenge_rewards, :fulfilled_at
  end
end
