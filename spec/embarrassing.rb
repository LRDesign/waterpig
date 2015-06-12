require 'sequel'
Sequel.sqlite

require 'waterpig'
require 'waterpig/deadbeat-connections'
module ActiveRecord
  class Base
  end

  module Tasks
    class DatabaseTasks
    end
    class PostgresDatabaseTasks
    end
  end

  class Migration
  end

  class Migrator
  end

  class Schema
  end
end
require 'waterpig/request-wait-middleware'
require 'waterpig/template-refresh'

describe "Nothing" do
  it "should do more" do
    puts "These tests really have to test the code"
  end
end
