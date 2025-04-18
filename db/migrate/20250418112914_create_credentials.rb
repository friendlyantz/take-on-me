class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname
      t.bigint :sign_count, default: 0, null: false
      t.timestamps

      t.index :external_id, unique: true
    end
  end
end
