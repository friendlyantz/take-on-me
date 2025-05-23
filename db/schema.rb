# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_03_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "challenge_comment_likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "challenge_comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_comment_id"], name: "index_challenge_comment_likes_on_challenge_comment_id"
    t.index ["user_id", "challenge_comment_id"], name: "index_comment_likes_on_user_and_comment", unique: true
    t.index ["user_id"], name: "index_challenge_comment_likes_on_user_id"
  end

  create_table "challenge_comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "message", null: false
    t.uuid "challenge_participant_id", null: false
    t.uuid "challenge_story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_participant_id"], name: "index_challenge_comments_on_challenge_participant_id"
    t.index ["challenge_story_id"], name: "index_challenge_comments_on_challenge_story_id"
  end

  create_table "challenge_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "user_id", null: false
    t.uuid "challenge_story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "active", null: false
    t.index ["challenge_story_id"], name: "index_challenge_participants_on_challenge_story_id"
    t.index ["status"], name: "index_challenge_participants_on_status"
    t.index ["user_id", "challenge_story_id"], name: "index_challenge_participants_on_user_id_and_challenge_story_id", unique: true
    t.index ["user_id"], name: "index_challenge_participants_on_user_id"
  end

  create_table "challenge_rewards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "giver_id", null: false
    t.uuid "receiver_id", null: false
    t.uuid "challenge_story_id", null: false
    t.string "description", null: false
    t.string "status", default: "pending", null: false
    t.datetime "fulfilled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_story_id"], name: "index_challenge_rewards_on_challenge_story_id"
    t.index ["giver_id", "receiver_id", "challenge_story_id"], name: "index_challenge_rewards_on_participants_and_story", unique: true
    t.index ["giver_id"], name: "index_challenge_rewards_on_giver_id"
    t.index ["receiver_id"], name: "index_challenge_rewards_on_receiver_id"
  end

  create_table "challenge_stories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description", default: "", null: false
    t.date "start", null: false
    t.date "finish", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "challenge_story_likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "challenge_story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_story_id"], name: "index_challenge_story_likes_on_challenge_story_id"
    t.index ["user_id", "challenge_story_id"], name: "index_challenge_story_likes_on_user_and_story", unique: true
    t.index ["user_id"], name: "index_challenge_story_likes_on_user_id"
  end

  create_table "credentials", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "external_id", null: false
    t.string "public_key", null: false
    t.string "nickname"
    t.bigint "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.citext "username", null: false
    t.string "webauthn_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "challenge_comment_likes", "challenge_comments"
  add_foreign_key "challenge_comment_likes", "users"
  add_foreign_key "challenge_comments", "challenge_participants"
  add_foreign_key "challenge_comments", "challenge_stories"
  add_foreign_key "challenge_participants", "challenge_stories"
  add_foreign_key "challenge_participants", "users"
  add_foreign_key "challenge_rewards", "challenge_participants", column: "giver_id"
  add_foreign_key "challenge_rewards", "challenge_participants", column: "receiver_id"
  add_foreign_key "challenge_rewards", "challenge_stories"
  add_foreign_key "challenge_story_likes", "challenge_stories"
  add_foreign_key "challenge_story_likes", "users"
  add_foreign_key "credentials", "users"
end
