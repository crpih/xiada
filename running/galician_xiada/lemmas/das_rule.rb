require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  class DasRule < Rule
    include Utils

    def initialize(all_possible_tags, noun_common_fp: 'Scfp', verb_indicative_present_2p: 'Vpi20p')
      super(all_possible_tags)
      @tags = tags_for(noun_common_fp, verb_indicative_present_2p)
    end

    def apply_query(query)
      query.word.end_with?('dás') ? query.copy("#{query.word.delete_suffix('dás')}dades", @tags) : nil
    end

    def apply_result(result) = result
  end
end
