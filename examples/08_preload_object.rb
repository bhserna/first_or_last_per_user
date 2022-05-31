require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
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

class FirstPostPerUser
  def initialize(users)
    @users = users
  end

  def [](user)
    posts[user.id]
  end

  def posts
    @posts ||= Post.first_per_user.index_by(&:user_id)
  end
end

users = User.all
posts = FirstPostPerUser.new(users)
puts users.map { |user| posts[user].title }
# SELECT "users".* FROM "users"
# SELECT "posts".*
# FROM "posts"
# WHERE "posts"."id" IN (SELECT min(id) FROM "posts" GROUP BY "posts"."user_id")