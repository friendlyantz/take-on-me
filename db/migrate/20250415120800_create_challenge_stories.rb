class CreateChallengeStories < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_stories, id: :uuid do |t|
      t.string :title, null: false
      t.string :description, null: false, default: ""
      t.date :start, null: false
      t.date :finish, null: false

      t.timestamps
    end
  end
end
