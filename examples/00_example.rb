require_relative "config"
require_relative "../lib/models"

puts Post.first_per_user
# => SELECT "posts".*
#    FROM "posts"
#    WHERE "posts"."id"
#    IN (SELECT min(id) FROM "posts" GROUP BY "posts"."user_id")

puts Post.last_per_user
# => SELECT "posts".*
#    FROM "posts"
#    WHERE "posts"."id"
#    IN (SELECT max(id) FROM "posts" GROUP BY "posts"."user_id")
