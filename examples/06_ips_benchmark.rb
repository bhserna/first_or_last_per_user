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


puts ""
puts "Ips Benchmark"
puts "---------"

Benchmark.ips do |benchmark|
  benchmark.config(:time => 5, :warmup => 1)

  benchmark.report("min") do
    Post.first_per_user_using_min.map(&:id)
  end

  benchmark.report("distinct_on") do
    Post.first_per_user_using_distinct_on.map(&:id)
  end

  benchmark.report("distinct_on arel") do
    Post.first_per_user_using_distinct_on_arel.map(&:id)
  end

  benchmark.report("lateral_join") do
    Post.first_per_user_using_lateral_join.map(&:id)
  end

  benchmark.report("window_function") do
    Post.first_per_user_using_window_function.map(&:id)
  end

  benchmark.compare!
end