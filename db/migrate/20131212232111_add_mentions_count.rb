class AddMentionsCount < ActiveRecord::Migration
  def change
    add_column :handles, :mentions_count, :integer, null: false, default: 0
  end
end
