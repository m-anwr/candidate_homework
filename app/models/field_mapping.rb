class FieldMapping < ApplicationRecord
  belongs_to :connection
  delegate :path, to: :connection
end
