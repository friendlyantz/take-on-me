# frozen_string_literal: true

# Base class for all SitePrism pages
# Supports default URL parameters (e.g., for show pages with :id)
class BasePage < SitePrism::Page
  class << self
    # Override .section to create anonymous sections easier
    def section(name, *args, &block)
      return super if args.first.is_a?(Class) || block_given?

      super(name, SitePrism::Section, *args)
    end
  end

  # You can create a new page by passing a params hash
  # or by providing a record to use as an /:id param
  def initialize(record_or_params = {})
    record_or_params = {id: record_or_params.to_param} if record_or_params.respond_to?(:to_param)
    @default_params = record_or_params
    super()
  end

  def load(expansion_or_html = {}, &block)
    expansion_or_html = expansion_or_html.reverse_merge(default_params) if expansion_or_html.is_a?(Hash)
    super
  end

  def displayed?(*args)
    expected_mappings = args.last.is_a?(::Hash) ? args.pop : {}
    expected_mappings = expected_mappings.reverse_merge(default_params)
    super(*args, expected_mappings)
  end

  private

  attr_reader :default_params
end
