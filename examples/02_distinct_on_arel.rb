require_relative "config"

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    from(order(:user_id, id: :asc).arel.distinct_on(arel_table[:user_id]).as("posts"))
  }

  scope :last_per_user, -> {
    from(order(:user_id, id: :desc).arel.distinct_on(arel_table[:user_id]).as("posts"))
  }
end

puts Post.first_per_user.map(&:id)
# => SELECT "posts".*
#    FROM "posts"
#    WHERE "posts"."id"
#    IN (SELECT min(id) FROM "posts" GROUP BY "posts"."user_id")

puts Post.last_per_user.map(&:id)
# => SELECT "posts".*
#    FROM "posts"
#    WHERE "posts"."id"
#    IN (SELECT max(id) FROM "posts" GROUP BY "posts"."user_id")
