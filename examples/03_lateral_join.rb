require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    selected_posts = User
      .select("selected_posts.*")
      .joins(<<-SQL)
        JOIN LATERAL (
          SELECT * FROM posts
          WHERE user_id = users.id
          ORDER BY id ASC LIMIT 1
        ) AS selected_posts ON TRUE
      SQL

    from(selected_posts, "posts")
  }

  scope :last_per_user, -> {
    selected_posts = User
      .select("selected_posts.*")
      .joins(<<-SQL)
        JOIN LATERAL (
          SELECT * FROM posts
          WHERE user_id = users.id
          ORDER BY id DESC LIMIT 1
        ) AS selected_posts ON TRUE
      SQL

    from(selected_posts, "posts")
  }
end

puts Post.first_per_user.map(&:id)
# => SELECT "posts".* FROM (SELECT selected_posts.* FROM "users" JOIN LATERAL (
#     SELECT * FROM posts
#     WHERE user_id = users.id
#     ORDER BY id ASC LIMIT 1
#   ) AS selected_posts ON TRUE) posts

puts Post.last_per_user.map(&:id)
# => SELECT "posts".* FROM (SELECT selected_posts.* FROM "users" JOIN LATERAL (
#     SELECT * FROM posts
#     WHERE user_id = users.id
#     ORDER BY id DESC LIMIT 1
#   ) AS selected_posts ON TRUE) posts
