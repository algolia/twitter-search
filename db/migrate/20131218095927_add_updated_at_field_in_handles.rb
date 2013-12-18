class AddUpdatedAtFieldInHandles < ActiveRecord::Migration
  def change
    add_column :handles, :updated_at, :datetime
  end
end
