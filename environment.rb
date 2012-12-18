# require ALL THE GEMS!
require 'bundler'
Bundler.require

# other stuff
require 'benchmark'

# monkey-patch Hash
class Hash
  def deep_merge! (h2)
    h2.each do |k, v|
      # If key already exists...
      if self.has_key?(k) then
        # ...and its value is a hash, go down recursively.
        if self[k].is_a?(Hash) and v.is_a?(Hash) then
          self[k].deep_merge!(v)
        # If its value is not a hash, add value from h2 to existing value.
        # (In this case, if its not a hash it will always be an integer)
        else
          self[k] += v
        end
      # If the key does not exists, just copy from h2.
      else
        self[k] = v
      end
    end
  end
end

# setup filepaths
DATA_DIRECTORY = File.join(Dir.pwd, 'data')
OUTPUT_DIRECTORY = File.join(Dir.pwd, 'app', 'scripts', 'data')

def LOG(who, who_color, what, what_color=:white)
  puts "[#{who.colorize(who_color)}] #{what.colorize(what_color)}"
end

# Load the datamapper config
# DataMapper::Logger.new(STDOUT, :debug)
#DataMapper.setup(:default, "sqlite:///#{File.join(DATA_DIRECTORY, 'census.db')}")
DataMapper.setup(:default, 'sqlite::memory:')

# General files
require './lib/models'
require './lib/importer'
require './lib/exporter'
