module Pupa
  # A voter's vote in a vote event.
  class Vote
    include Model

    self.schema = File.expand_path(File.join('..', '..', '..', 'schemas', 'popolo', 'vote.json'), __dir__)

    include Concerns::Timestamps
    include Concerns::Sourceable

    attr_accessor :vote_event_id, :voter_id, :option, :group_id, :role, :weight, :pair_id
    dump          :vote_event_id, :voter_id, :option, :group_id, :role, :weight, :pair_id

    foreign_key :vote_event_id, :voter_id, :group_id, :pair_id

    # Returns the vote's option, voter ID and vote event ID.
    #
    # @return [String] the vote's option, voter ID and vote event ID
    def to_s
      "#{option} by #{voter_id} in #{vote_event_id}"
    end
  end
end
