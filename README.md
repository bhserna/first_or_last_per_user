# Simple first or last per user

This example is based on a [proposal](https://twitter.com/stevepolitodsgn/status/1503345127846301703) of [Steave Polito](https://twitter.com/stevepolitodsgn).

Have you ever needed to get the most recent record for each user in rails, but didn't know how to do it without using map?

Here is an example of a simple way to do it when you can use the `id` column to sort the records.

```ruby
class Post < ActiveRecord::Base
  belongs_to :user

  scope :first_per_user, -> {
    where(id: select("min(id)").group(:user_id))
  }

  scope :last_per_user, -> {
    where(id: select("max(id)").group(:user_id))
  }
end

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
```

## How to run the examples

1. **Install the dependencies** with `bundle install`.

2. **Database setup** - run the command:

```
ruby db/setup.rb
```

3. **Run the examples** with `ruby examples/<file name>`. For example:

```
ruby example/00_example.rb
```

4. **Change the seeds**  on `db/seeds.rb` and re-run `ruby db/setup.rb` to test different scenarios.
