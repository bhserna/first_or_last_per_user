require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
  has_one :first_post, -> { first_per_user }, class_name: "Post"
  has_one :last_post, -> { last_per_user }, class_name: "Post"
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    where(id: select("min(id)").group(:user_id))
  }

  scope :last_per_user, -> {
    where(id: select("max(id)").group(:user_id))
  }
end

users = User.preload(:first_post)
puts users.map(&:first_post).map(&:title)
# SELECT "users".* FROM "users"
# SELECT "posts".*
# FROM "posts"
# WHERE "posts"."id" IN (SELECT min(id) FROM "posts" GROUP BY "posts"."user_id")
# AND "posts"."user_id" IN (...)  [...]

users = User.preload(:last_post)
puts users.map(&:last_post).map(&:title)
# SELECT "users".* FROM "users"
# SELECT "posts".*
# FROM "posts"
# WHERE "posts"."id" IN (SELECT max(id) FROM "posts" GROUP BY "posts"."user_id")
# AND "posts"."user_id" IN (...)  [...]