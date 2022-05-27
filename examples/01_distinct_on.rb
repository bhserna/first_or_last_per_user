require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    from(select("DISTINCT ON (posts.user_id) posts.*").order(:user_id, id: :asc), "posts")
  }

  scope :last_per_user, -> {
    from(select("DISTINCT ON (posts.user_id) posts.*").order(:user_id, id: :desc), "posts")
  }
end

puts Post.first_per_user.map(&:id)
# => SELECT "posts".* FROM (
#      SELECT DISTINCT ON (posts.user_id) posts.*
#      FROM "posts"
#      ORDER BY "posts"."user_id" ASC, "posts"."id" ASC
#    ) posts

puts Post.last_per_user.map(&:id)
# => SELECT "posts".* FROM (
#      SELECT DISTINCT ON (posts.user_id) posts.*
#      FROM "posts"
#      ORDER BY "posts"."user_id" DESC, "posts"."id" DESC
#    ) posts