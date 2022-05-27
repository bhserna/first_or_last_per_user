require_relative "config"
require_relative "../lib/models"
require "ffaker"

def create_users(count, &block)
  users_data = count.times.map(&block)
  user_ids = User.insert_all(users_data, unique_by: :id, record_timestamps: true).map { |data| data["id"] }
  User.where(id: user_ids)
end

def create_posts(users, count, &block)
  posts_data = users.flat_map { |user| count.times.map { block.(user) } }
  Post.insert_all(posts_data, record_timestamps: true)
end

users = create_users(100) do
  { name: FFaker::Name.name }
end

create_posts(users, 100) do |user|
  { user_id: user.id, title: FFaker::CheesyLingo.title, body: FFaker::CheesyLingo.paragraph }
end
