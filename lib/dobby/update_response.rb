# frozen_string_literal: true

module Dobby
  # A generic response format.
  class UpdateResponse
    attr_reader :content
    # @param changed [Boolean]
    # @param content [Hash]
    def initialize(changed, content = nil)
      @changed = changed
      @content = content
    end

    # @return [Boolean]
    def changed?
      @changed == true
    end
  end
end
