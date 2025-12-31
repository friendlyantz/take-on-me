class AddCounterCachesToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :challenge_stories, :challenge_story_likes_count, :integer, default: 0, null: false
    add_column :challenge_stories, :challenge_comments_count, :integer, default: 0, null: false
    add_column :challenge_stories, :challenge_participants_count, :integer, default: 0, null: false
    add_column :challenge_stories, :challenge_rewards_count, :integer, default: 0, null: false
    
    add_column :challenge_comments, :challenge_comment_likes_count, :integer, default: 0, null: false
    
    add_column :users, :challenge_participants_count, :integer, default: 0, null: false
    add_column :users, :challenge_story_likes_count, :integer, default: 0, null: false
    
    add_column :challenge_participants, :given_rewards_count, :integer, default: 0, null: false
    add_column :challenge_participants, :received_rewards_count, :integer, default: 0, null: false
    add_column :challenge_participants, :challenge_comments_count, :integer, default: 0, null: false
  end
end
