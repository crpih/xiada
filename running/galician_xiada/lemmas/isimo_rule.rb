# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'utils'

module Lemmas
  class IsimoRule < Rule
    include Utils

    VALID_TISIMO = %w[abert absolt acolleit avolt colleit comest cubert descrit descubert desenvolt devolt disolt encolleit encubert entreabert envolt enxoit ergueit escolleit escrit frit mort prescrit proscrit provist recolleit recubert resolt revolt].freeze
    VALID_SISIMO = %w[aces apres impres pres].freeze

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @a_tags = tags_for('A.*')
      @av_tags = tags_for('V0p.*', 'A.*')
      @a_gn_tags = tags_by_gn('A.*')
    end

    def apply_query(query)
      return unless query.word.match(/(.+)ísim([oa])(s?)\z/)

      base, g, n = Regexp.last_match.captures

      if base.end_with?('bil')
        # amabilísimo => amable
        query.copy("#{base.delete_suffix('il')}le#{n}", @a_gn_tags[g][n])
      elsif base.end_with?('qu')
        # riquísimo => rico
        query.copy("#{base.delete_suffix('qu')}c#{g}#{n}", @a_tags)
      elsif base.end_with?('gu')
        # vaguísimo => vago
        query.copy("#{base.delete_suffix('u')}#{g}#{n}", @a_tags)
      elsif base.end_with?('gü')
        # ambigüísimo => ambiguo / pingüísimo => pingüe
        search_base = base.delete_suffix('ü')
        [query.copy("#{search_base}u#{g}#{n}", @a_tags),
         query.copy("#{search_base}üe#{n}", @a_gn_tags[g][n])]
      elsif base.end_with?('i')
        # friísimo => frío
        query.copy("#{base.delete_suffix('i')}í#{g}#{n}", @a_tags)
      elsif base == 'cool'
        # Plural exception: cool
        query.copy(base, @a_gn_tags[g][n])
      elsif base.end_with?('l')
        # virtualísimo => virtual / facilísimo => fácil
        if n == 's' # For plural
          tilde_variants("#{base}es").map { |v| query.copy(v, @a_gn_tags[g][n]) }
        else
          tilde_variants(base).map { |v| query.copy(v, @a_gn_tags[g][n]) }
        end
      elsif base.end_with?('c')
        # ferocísimo => feroz / docísimo => doce
        search_base = base.delete_suffix('c')
        sp_common_query = query.copy("#{search_base}z", @a_gn_tags[g][n])
        if n == 's' # For plural
          [sp_common_query, query.copy("#{search_base}ces", @a_gn_tags[g][n])]
        else
          [sp_common_query, query.copy("#{search_base}ce", @a_gn_tags[g][n])]
        end
      elsif base.end_with?('ad')
        # preparadísimo => preparado
        query.copy("#{base}#{g}#{n}", @av_tags)
      elsif base.end_with?('id')
        # convencidísimos => convencidos
        # extendidísima => extendida
        query.copy("#{base}#{g}#{n}", @av_tags)
      elsif base.end_with?('t') && VALID_TISIMO.include?(base)
        query.copy("#{base}#{g}#{n}", @av_tags)
      elsif base.end_with?('s') && VALID_SISIMO.include?(base)
        query.copy("#{base}#{g}#{n}", @av_tags)
      else
        # ísimo (default rule)
        # listísimo => listo
        # gravísimo => grave
        query.copy("#{base}#{g}#{n}", @a_gn_tags[g][n])
      end
    end

    def apply_result(query, result)
      g, n = query.prev.word.match(/ísim([oa])(s?)\z/).captures

      # Apply "superlativo" to tag.
      # Forcefully replace gender and number of the tag based on the original word gender and number
      # TODO: Investigate if it is better to perform the search with the correct tags to begin with
      tag = replace_tag_gn(result.tag.sub(/\AA0/, 'As'), g, n)

      result.copy(replace_tag_gn(tag, g, n))
    end
  end
end
