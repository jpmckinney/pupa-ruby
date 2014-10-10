module Pupa
  # An event at which people's votes are recorded.
  class VoteEvent
    include Model

    self.schema = 'popolo/vote_event'

    include Concerns::Timestamps
    include Concerns::Sourceable

    attr_accessor :identifier, :motion_id, :organization_id, :legislative_session_id, :start_date, :end_date, :result
    dump          :identifier, :motion_id, :organization_id, :legislative_session_id, :start_date, :end_date, :result

    foreign_key :motion_id, :organization_id, :legislative_session_id

    # Returns the vote event's identifier and organization ID.
    #
    # @return [String] the vote event's identifier and organization ID
    def to_s
      "#{identifier} in #{organization_id}"
    end
  end
end
