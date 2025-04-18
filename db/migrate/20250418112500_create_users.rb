class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :username, null: false
      t.string :webauthn_id
      t.timestamps

      t.index :username, unique: true
    end
  end
end
