class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # you get versions! and you get versions! everybody gets versions!!!
  has_paper_trail
end
