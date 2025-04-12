# frozen_string_literal: true

# Capybara settings (not covered by Rails system tests)

# Don't wait too long in `have_xyz` matchers
Capybara.default_max_wait_time = 2

# Normalizes whitespaces when using `has_text?` and similar matchers
Capybara.default_normalize_ws = true

# Where to store artifacts (e.g. screenshots, downloaded files, etc.)
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# The Capybara.using_session allows you to manipulate a different browser session, and thus,
#  multiple independent sessions within a single test scenario.
#  That’s especially useful for testing real-time features, e.g., something with WebSocket.
# This patch tracks the name of the last session used.
#  We’re going to use this information to support taking failure screenshots in multi-session tests.
Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &block)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)

require "capybara/rspec"
Capybara.server = :thruster
