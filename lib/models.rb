# This is only an IR.
# if you were actually using it for a database, you'd do it differently.
class State
  include DataMapper::Resource

  property :id,          Serial    # An auto-increment integer key
  property :number,      String    # 1
  property :name,        String    # Alabama

  has n, :estimates
end

class Estimate
  include DataMapper::Resource

  property :id,          Serial    # An auto-increment integer key
  property :county_name, String    # Autauga County
  property :county_id,   String    # 1
  property :fips_id,     String    # 01001
  property :population,  Integer   # A text block, for longer string data.
  property :year,        String    # year of the estimate

  belongs_to :state
end

DataMapper.finalize
DataMapper.auto_upgrade!
