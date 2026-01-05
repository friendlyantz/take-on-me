class CreateWebPushNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :web_push_notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}, type: :uuid
      t.string :endpoint, null: false
      t.string :auth_key, null: false
      t.string :p256dh_key, null: false
      t.string :device_name
      t.text :user_agent

      t.timestamps
    end

    add_index :web_push_notifications, [:user_id, :endpoint], unique: true
  end
end
