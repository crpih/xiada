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

      case
      when base.end_with?('bil') then apply_bil(query, base, g, n)
      when base.end_with?('qu') then apply_qu(query, base, g, n)
      when base.end_with?('gu') then apply_gu(query, base, g, n)
      when base.end_with?('gü') then apply_gu_diaeresis(query, base, g, n)
      when base.end_with?('i') then apply_i(query, base, g, n)
      when base == 'cool' then apply_cool(query, base, g, n)
      when base.end_with?('l') then apply_l(query, base, g, n)
      when base.end_with?('c') then apply_c(query, base, g, n)
      when base.end_with?('ad') then apply_ad(query, base, g, n)
      when base.end_with?('id') then apply_id(query, base, g, n)
      when base.end_with?('t') && VALID_TISIMO.include?(base) then apply_tisimo(query, base, g, n)
      when base.end_with?('s') && VALID_SISIMO.include?(base) then apply_sisimo(query, base, g, n)
      else apply_default(query, base, g, n)
      end
    end

    def apply_result(result)
      g, n = result.query.each { |q| break Regexp.last_match.captures if q.word.match(/ísim([oa])(s?)\z/) }

      # Apply "superlativo" to tag.
      # Forcefully replace gender and number of the tag based on the original word gender and number
      # TODO: Investigate if it is better to perform the search with the correct tags to begin with
      tag = replace_tag_gn(result.tag.sub(/\AA0/, 'As'), g, n)

      result.copy(replace_tag_gn(tag, g, n))
    end

    private

    # amabilísimo => amable
    def apply_bil(query, base, g, n)
      query.copy("#{base.delete_suffix('il')}le#{n}", @a_gn_tags[g][n])
    end

    # riquísimo => rico
    def apply_qu(query, base, g, n)
      query.copy("#{base.delete_suffix('qu')}c#{g}#{n}", @a_tags)
    end

    # vaguísimo => vago
    def apply_gu(query, base, g, n)
      query.copy("#{base.delete_suffix('u')}#{g}#{n}", @a_tags)
    end

    # ambigüísimo => ambiguo
    # pingüísimo => pingüe
    def apply_gu_diaeresis(query, base, g, n)
      search_base = base.delete_suffix('ü')
      [query.copy("#{search_base}u#{g}#{n}", @a_tags),
       query.copy("#{search_base}üe#{n}", @a_gn_tags[g][n])]
    end

    # friísimo => frío
    def apply_i(query, base, g, n)
      query.copy("#{base.delete_suffix('i')}í#{g}#{n}", @a_tags)
    end

    # Plural exception: cool
    def apply_cool(query, base, g, n)
      query.copy(base, @a_gn_tags[g][n])
    end

    # virtualísimo => virtual
    # facilísimo => fácil
    def apply_l(query, base, g, n)
      if n == 's' # For plural
        tilde_variants("#{base}es").map { |v| query.copy(v, @a_gn_tags[g][n]) }
      else
        tilde_variants(base).map { |v| query.copy(v, @a_gn_tags[g][n]) }
      end
    end

    # ferocísimo => feroz
    # docísimo => doce
    def apply_c(query, base, g, n)
      search_base = base.delete_suffix('c')
      sp_common_query = query.copy("#{search_base}z", @a_gn_tags[g][n])
      if n == 's' # For plural
        [sp_common_query, query.copy("#{search_base}ces", @a_gn_tags[g][n])]
      else
        [sp_common_query, query.copy("#{search_base}ce", @a_gn_tags[g][n])]
      end
    end

    # preparadísimo => preparado
    def apply_ad(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @av_tags)
    end

    # convencidísimos => convencidos
    # extendidísima => extendida
    def apply_id(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @av_tags)
    end

    def apply_tisimo(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @av_tags)
    end

    def apply_sisimo(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @av_tags)
    end

    # ísimo (default rule)
    # listísimo => listo
    # gravísimo => grave
    def apply_default(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @a_gn_tags[g][n])
    end
  end
end
