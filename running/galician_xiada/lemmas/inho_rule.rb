# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'utils'

module Lemmas
  class InhoRule < Rule
    include Utils

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
      return unless query.word.match(/(.+)iñ([oa])(s?)\z/) && !query.word.include?('-')

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
        if n == 's' # When plural
          [*query.copy("#{search_base}es", @tags),
           *query.copy("#{search_base}z#{g}#{n}", @tags)]
        else
          [*query.copy(search_base, @tags),
           *query.copy("#{search_base}z#{g}#{n}", @tags)]
        end
      elsif base.end_with?('qu')
        # quiño/a/os/as
        # plaquiñas => placas
        # retaquiños => retacos
        # musiquiña => música
        # musiquiño => músico
        # faisquiñas => faíscas
        # periodiquiños => periódicos
        # politiquiñas => políticas
        search_base = "#{base}c#{g}#{n}"
        [*query.copy(search_base, @tags),
         *query.copy(search_base, @v_tags),
         *tilde_variants(search_base).map { |v| query.copy(v, @tags) }]
      end
    end

    def apply_result(query, result)
      g, n = query.prev.word.match(/iñ([oa])(s?)\z/).captures

      # Forcefully replace gender and number of the tag based on the original word gender and number
      # TODO: Investigate if it is better to perform the search with the correct tags to begin with
      result.copy(replace_tag_gn(result.tag, g, n))
    end
  end
end
