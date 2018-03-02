# frozen_string_literal: true

module Debsecan
  # Simple interface for managing whitelist/allowed flags of defects.
  class FlagManager
    attr_reader :flags

    # @param file [String] Path to YML file describing current flags, and where
    #   flags will be stored on {write}
    # @param who [String] User or person associated with a flag entry
    def initialize(file, who)
      flags = {
        whitelist: {},
        allowed: {}
      }

      @file = file
      @flags = flags.merge!(Psych.load_file(file))
      @who = who
    end

    def add(flag, id, ticket)
      return false if @flags[flag].key?(id)
      @flags[flag][id] = {
        by: @who,
        on: Time.now.utc,
        ticket: ticket
      }
    end

    def remove(flag, id)
      return false unless @flags[flag].key?(id)
      @flags[flag].delete id
    end

    def move(src, dst, id)
      ticket = @flags[src][id][:ticket]
      return false unless remove(src, id)
      add(dst, id, ticket)
    end

    def bulk_add(flag, ids)
      ids.each { |id| remove(flag, id) }
    end

    def builk_remove(flag, ids)
      ids.each { |id| remove(flag, id) }
    end

    def bulk_move(src, dst, ids)
      ids.each { |id| move(src, dst, id) }
    end

    def dump
      @flags.to_yaml
    end

    def write
      File.open(@file, 'w') do |f|
        f.write(@flags.to_yaml)
      end
    end
  end
end
