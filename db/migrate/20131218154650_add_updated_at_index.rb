class AddUpdatedAtIndex < ActiveRecord::Migration
  def change
    add_index :handles, :updated_at
  end
end
