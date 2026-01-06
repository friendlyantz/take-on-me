class RenameCommentsToCheckIns < ActiveRecord::Migration[8.0]
  def change
    # Rename tables
    rename_table :challenge_comments, :challenge_check_ins
    rename_table :challenge_comment_likes, :challenge_check_in_likes

    # Rename foreign key column in challenge_check_in_likes
    rename_column :challenge_check_in_likes, :challenge_comment_id, :challenge_check_in_id

    # Rename counter cache columns
    rename_column :challenge_participants, :challenge_comments_count, :challenge_check_ins_count
    rename_column :challenge_stories, :challenge_comments_count, :challenge_check_ins_count
    rename_column :challenge_check_ins, :challenge_comment_likes_count, :challenge_check_in_likes_count

    # Note: Indexes, foreign keys, and check constraints are automatically renamed by PostgreSQL
    # when tables and columns are renamed, so no manual updates needed
  end
end
