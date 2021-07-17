class Connection < ApplicationRecord
    belongs_to :integration
    has_many :field_mappings, dependent: :destroy
end
