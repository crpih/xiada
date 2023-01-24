# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class InhoRule < Rule
    TAG_PATTERNS = %w[].freeze

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('Sc.*', 'A.*', 'V0p0.*', 'V0x000', 'W.*', 'I.*').freeze
      @v_tags = tags_for('V.i.*','V.s','V0m.').freeze
      @sc_a0_tags = tags_for('Scf.*','A0f.*').freeze
      @sa_tags = tags_for('S.*', 'A.*').freeze
      @sai_tags = tags_for('S.*', 'A.*', 'I.*').freeze
      @saiw_tags = tags_for('S.*', 'A.*', 'I.*', 'W.*').freeze
      @saiv_tags = tags_for('S.*', 'A.*', 'I.*', 'V0p0.*').freeze
      @sav_tags = tags_for('S.*', 'A.*', 'V0p0.*').freeze
    end

    def apply_query(query)
      return unless query.search_word.match(/(.+)iñ([oa])(s?)\z/) && !query.search_word.include?('-')

      base, g, n = Regexp.last_match.captures

      if base.end_with?('gu')
        # amiguiño => amigo
        # enruguiñas => enruga
        # albondiguiñas => albóndiga
        # estomaguiño => estómago
        query.copy("#{base.delete_suffix('u')}#{g}#{n}", @tags)
      elsif base.end_with?('lc')
        # solciño => sol (Scms)
        # animalciños => animal (Scmp)
        # descalciña => descalzo
        search_base = base.delete_suffix('c')
        [*query.copy(search_base, @tags),
         *query.copy("#{search_base}es", @tags),
         *query.copy("#{search_base}z#{g}#{n}", @tags)]
      elsif base.end_with?('qu')
        # quiño/a/os/as
        # plaquiñas => placas
        # retaquiños => retacos
        # TODO
      end
    end
  end
end
