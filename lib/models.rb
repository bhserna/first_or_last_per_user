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
