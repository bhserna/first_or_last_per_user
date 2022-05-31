require_relative "config"
require "benchmark"
require "benchmark/memory"
require "benchmark/ips"

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user_using_min, -> {
    where(id: select("min(id)").group(:user_id))
  }

  scope :first_per_user_using_distinct_on, -> {
    from(select("DISTINCT ON (posts.user_id) posts.*").order(:user_id, id: :asc), "posts")
  }

  scope :first_per_user_using_distinct_on_arel, -> {
    from(order(:user_id, id: :asc).arel.distinct_on(arel_table[:user_id]).as("posts"))
  }

  scope :first_per_user_using_lateral_join, -> {
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

  scope :first_per_user_using_window_function, -> {
    ranked_posts = select(<<-SQL)
      posts.*,
      dense_rank() OVER (
        PARTITION BY posts.user_id
        ORDER BY posts.id ASC
      ) AS posts_rank
    SQL

    from(ranked_posts, "posts").where("posts_rank <= 1")
  }
end


n = 1
puts ""
puts "Memory Benchmark"
puts "---------"

Benchmark.memory do |benchmark|
  benchmark.report("min") do
    n.times do
      Post.first_per_user_using_min.map(&:id)
    end
  end

  benchmark.report("distinct_on") do
    n.times do
      Post.first_per_user_using_distinct_on.map(&:id)
    end
  end

  benchmark.report("distinct_on arel") do
    n.times do
      Post.first_per_user_using_distinct_on_arel.map(&:id)
    end
  end

  benchmark.report("lateral_join") do
    n.times do
      Post.first_per_user_using_lateral_join.map(&:id)
    end
  end

  benchmark.report("window_function") do
    n.times do
      Post.first_per_user_using_window_function.map(&:id)
    end
  end

  benchmark.compare!
end

# Memory Benchmark
# ---------
# Calculating -------------------------------------
# D, [2022-05-30T07:21:45.392573 #89404] DEBUG -- :   Post Load (5.9ms)  SELECT "posts".* FROM "posts" WHERE "posts"."id" IN (SELECT min(id) FROM "posts" GROUP BY "posts"."user_id")
#                  min     1.089M memsize (   189.068k retained)
#                         11.213k objects (     1.616k retained)
#                         50.000  strings (    50.000  retained)
#
# D, [2022-05-30T07:21:45.626151 #89404] DEBUG -- :   Post Load (21.3ms)  SELECT "posts".* FROM (SELECT DISTINCT ON (posts.user_id) posts.* FROM "posts" ORDER BY "posts"."user_id" ASC, "posts"."id" ASC) posts
#          distinct_on   156.915k memsize (   264.000  retained)
#                          1.259k objects (     3.000  retained)
#                         50.000  strings (     3.000  retained)
#
# D, [2022-05-30T07:21:45.773654 #89404] DEBUG -- :   Post Load (16.9ms)  SELECT "posts".* FROM (SELECT DISTINCT ON ( "posts"."user_id" ) "posts".* FROM "posts" ORDER BY "posts"."user_id" ASC, "posts"."id" ASC) posts
#     distinct_on arel   155.665k memsize (   128.000  retained)
#                          1.262k objects (     2.000  retained)
#                         50.000  strings (     2.000  retained)
#
# D, [2022-05-30T07:21:45.971812 #89404] DEBUG -- :   Post Load (63.6ms)  SELECT "posts".* FROM (SELECT selected_posts.* FROM "users" JOIN LATERAL (
#           SELECT * FROM posts
#           WHERE user_id = users.id
#           ORDER BY id ASC LIMIT 1
#         ) AS selected_posts ON TRUE) posts
#         lateral_join   224.854k memsize (    11.781k retained)
#                          2.030k objects (   120.000  retained)
#                         50.000  strings (    50.000  retained)
#
# D, [2022-05-30T07:21:46.126473 #89404] DEBUG -- :   Post Load (22.6ms)  SELECT "posts".* FROM (SELECT       posts.*,
#       dense_rank() OVER (
#         PARTITION BY posts.user_id
#         ORDER BY posts.id ASC
#       ) AS posts_rank
#  FROM "posts") posts WHERE (posts_rank <= 1)
#      window_function   156.787k memsize (     0.000  retained)
#                          1.247k objects (     0.000  retained)
#                         50.000  strings (     0.000  retained)
#
# Comparison:
#     distinct_on arel:     155665 allocated
#      window_function:     156787 allocated - 1.01x more
#          distinct_on:     156915 allocated - 1.01x more
#         lateral_join:     224854 allocated - 1.44x more
#                  min:    1088714 allocated - 6.99x more