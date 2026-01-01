# Load general RSpec Rails configuration
require "rails_helper"

# Load configuration files and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |file| require file }

# Load page objects for SitePrism
Dir[File.join(__dir__, "system/pages/**/*.rb")].sort.each { |file| require file }
