ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Disable FK checks during fixture loading (fixtures load alphabetically,
    # so cross-table references can violate constraints before all tables are populated)
    setup do
      ActiveRecord::Base.connection.disable_referential_integrity { } rescue nil
    end

    # Add more helper methods to be used by all tests here...
  end
end
