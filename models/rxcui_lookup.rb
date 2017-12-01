# Simple lookup for rxcui to medication name
class RxcuiLookup < ActiveRecord::Base
  validates_presence_of :name
end
