class Episode < ActiveRecord::Base
  has_many :trajectory_optimizations
end
