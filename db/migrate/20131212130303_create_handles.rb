class CreateHandles < ActiveRecord::Migration
  def change
    create_table :handles do |t|
      t.string :screen_name, null: false, limit: 32
      t.string :name, limit: 32
      t.string :description, limit: 255
      t.integer :followers_count, null: false, default: 0
    end
    add_index :handles, :screen_name, unique: true
  end
end
