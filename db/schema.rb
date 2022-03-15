require_relative "config"

ActiveRecord::Schema.define(version: 1) do
  create_table :users, if_not_exists: true do |t|
    t.string :name
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :posts, if_not_exists: true do |t|
    t.integer :user_id
    t.string :title
    t.text :body
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  add_index :posts, :user_id, if_not_exists: true
end
