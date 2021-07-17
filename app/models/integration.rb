class Integration < ApplicationRecord
  has_many :connections, dependent: :destroy
end
