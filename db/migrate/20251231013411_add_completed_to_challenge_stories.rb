class AddCompletedToChallengeStories < ActiveRecord::Migration[8.0]
  def change
    add_column :challenge_stories, :completed, :boolean, default: false, null: false
  end
end
