require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    ranked_posts = select(<<-SQL)
      posts.*,
      dense_rank() OVER (
        PARTITION BY posts.user_id
        ORDER BY posts.id ASC
      ) AS posts_rank
    SQL

    from(ranked_posts, "posts").where("posts_rank <= 1")
  }

  scope :last_per_user, -> {
    ranked_posts = select(<<-SQL)
      posts.*,
      dense_rank() OVER (
        PARTITION BY posts.user_id
        ORDER BY posts.id DESC
      ) AS posts_rank
    SQL

    from(ranked_posts, "posts").where("posts_rank <= 1")
  }
end

puts Post.first_per_user.map(&:id)
# SELECT "posts".* FROM (SELECT posts.*,
#   dense_rank() OVER (
#     PARTITION BY posts.user_id
#     ORDER BY posts.id ASC
#   ) AS posts_rank
# FROM "posts") posts WHERE (posts_rank <= 1)

puts Post.last_per_user.map(&:id)
# SELECT "posts".* FROM (SELECT posts.*,
#   dense_rank() OVER (
#     PARTITION BY posts.user_id
#     ORDER BY posts.id DESC
#   ) AS posts_rank
# FROM "posts") posts WHERE (posts_rank <= 1)