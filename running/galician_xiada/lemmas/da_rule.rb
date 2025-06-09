require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  class DaRule < Rule
    include Utils

    def initialize(all_possible_tags, noun_common_fs: 'Scfs', verb_imperative_2p: 'V0m20p')
      super(all_possible_tags)
      @tags = tags_for(noun_common_fs, verb_imperative_2p)
    end

    def apply_query(query)
      query.word.end_with?('dá') ? query.copy("#{query.word.delete_suffix('dá')}dade", @tags) : nil
    end

    def apply_result(result) = result
  end
end
