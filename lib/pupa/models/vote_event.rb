module Pupa
  # An event at which people's votes are recorded.
  class VoteEvent
    include Model

    self.schema = 'schemas/popolo/vote_event.json'

    include Concerns::Timestamps
    include Concerns::Sourceable

    attr_accessor :identifier, :motion_id, :organization_id, :legislative_session_id, :start_date, :end_date, :result, :group_results, :counts
    dump          :identifier, :motion_id, :organization_id, :legislative_session_id, :start_date, :end_date, :result, :group_results, :counts

    foreign_key :motion_id, :organization_id, :legislative_session_id

    def initialize(*args)
      @group_results = []
      @counts = []
      super
    end

    # Returns the vote event's identifier and organization ID.
    #
    # @return [String] the vote event's identifier and organization ID
    def to_s
      "#{identifier} in #{organization_id}"
    end

    # Sets the group results.
    #
    # @param [Array] group_results a list of group results
    def group_results=(group_results)
      @group_results = symbolize_keys(group_results)
    end

    # Sets the counts.
    #
    # @param [Array] counts a list of counts
    def counts=(counts)
      @counts = symbolize_keys(counts)
    end

    # Adds a group result.
    #
    # @param [String] result the result of the vote event within a group of voters
    # @param [String] group a group of voters
    def add_group_result(result, group: nil)
      data = {result: result}
      if group
        data[:group] = group
      end
      if result.present?
        @group_results << data
      end
    end

    # Adds a count.
    #
    # @param [String] option an option in a vote event
    # @param [String] value the number of votes for an option
    # @param [String] group a group of voters
    def add_count(option, value, group: nil)
      data = {option: option, value: value}
      if group
        data[:group] = group
      end
      if option.present? && value.present?
        @counts << data
      end
    end
  end
end
