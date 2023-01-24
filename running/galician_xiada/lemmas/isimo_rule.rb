# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'tilde_transform'

module Lemmas
  class IsimoRule < Rule

    VALID_TISIMO = %w[abert absolt acolleit avolt colleit comest cubert descrit descubert desenvolt devolt disolt encolleit encubert entreabert envolt enxoit ergueit escolleit escrit frit mort prescrit proscrit provist recolleit recubert resolt revolt].freeze
    VALID_SISIMO = %w[aces apres impres pres].freeze

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tilde_transform = TildeTransform.new(all_possible_tags)
      # Precalculate tag lists
      @a_tags = tags_for('A.*').freeze
      @av_tags = tags_for('V0p.*', 'A.*').freeze
      @a_gn_tags = {
        'a' => { '' => tags_for('A.*fs').freeze, 's' => tags_for('A.*fp').freeze }.freeze,
        'o' => { '' => tags_for('A.*ms').freeze, 's' => tags_for('A.*mp').freeze }.freeze
      }.freeze
    end

    def apply_query(query)
      return unless query.search_word.match(/(.+)ísim([oa])(s?)\z/)

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
        @tilde_transform.apply_query(query).flat_map { |c| c.copy(c.search_word, @a_gn_tags[g][n]) }
      elsif base.end_with?('c')
        # ferocísimo => feroz / # docísimo => doce
        search_base = base.delete_suffix('c')
        [query.copy("#{search_base}z", @a_gn_tags[g][n]),
         query.copy("#{search_base}ces", @a_gn_tags[g][n])]
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
        query.copy(base, @a_gn_tags[g][n])
      end
    end

    def apply_result(result)
      result.copy(result.tag.sub(/\AA0/, 'As'))
    end

    private

    def gn_tag(gender_suffix, number_suffix)
      number_tag = number_suffix.nil? ? 's' : 'p'
      gender_suffix == 'o' ? "m#{number_tag}" : "f#{number_tag}"
    end
  end
end
