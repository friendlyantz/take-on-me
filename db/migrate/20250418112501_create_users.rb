class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.citext :username, null: false
      t.string :webauthn_id
      t.timestamps

      t.index :username, unique: true
    end
  end
end
