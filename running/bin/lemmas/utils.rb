# frozen_string_literal: true
require_relative "sensitivities"

module Lemmas
  module Utils
    include Sensitivities

    # NOTE: This function breaks statistical model in some way
    def replace_tags(dw_result, search_exp, replace_exp)
      dw_result.map { |w, *r| [w.gsub(/#{search_exp}/,"#{replace_exp}"), *r] }
    end

    # NOTE: This function breaks statistical model in some way
    def replace_lemmas(dw_result, search_exp, replace_exp)
      result = Array.new
      dw_result.each do |row|
        row[1].gsub!(/#{search_exp}/,"#{replace_exp}")
        result << row
      end
      return result
    end

    def replace_hiperlemmas(dw_result, search_exp, replace_exp)
      result = Array.new
      dw_result.each do |row|
        if search_exp && replace_exp
          row[2].gsub!(/#{search_exp}/,"#{replace_exp}") if row[2]
        else
          row[2]="#{replace_exp}" unless search_exp
        end
        result << row
      end
      return result
    end

    MAX_VARIANTS = 4_000

    def unaccented_variants(word)
      unaccented = word.tr('áéíóúüÁÉÍÓÚÜ', 'aeiouuAEIOUU')
      word == unaccented ? [word] : [word, unaccented]
    end

    def tilde_variants(word)
      independent_variants([
                             %w[a á], %w[A Á],
                             %w[e é], %w[E É],
                             %w[i í], %w[I Í],
                             %w[o ó], %w[O Ó],
                             %w[u ú], %w[U Ú]
                           ], MAX_VARIANTS, [word])
    end

    def gheada_variants(word)
      composed_variants([
                        %w[ga gha],
                        %w[gá ghá],
                        %w[gue ghe],
                        %w[gué ghé],
                        %w[gui ghi],
                        %w[guí ghí],
                        %w[go gho],
                        %w[gó ghó],
                        %w[gu ghu],
                        %w[gú ghú],
                        %w[gra ghra],
                        %w[grá ghrá],
                        %w[gre ghre],
                        %w[gré ghré],
                        %w[gri ghri],
                        %w[grí ghrí],
                        %w[gro ghro],
                        %w[gró ghró],
                        %w[gru ghru],
                        %w[grú ghrú],
                        %w[gla ghla],
                        %w[glá ghlá],
                        %w[gle ghle],
                        %w[glé ghlé],
                        %w[gli ghli],
                        %w[glí ghlí],
                        %w[glo ghlo],
                        %w[gló ghló],
                        %w[glu ghlu],
                        %w[glú ghlú],
      ], MAX_VARIANTS, [word])
    end

    def seseo_variants(word)
      composed_variants([
                        %w[za sa],
                        %w[zá sá],
                        %w[ce se],
                        %w[cé sé],
                        %w[ci si],
                        %w[cí sí],
                        %w[zo so],
                        %w[zó só],
                        %w[zu su],
                        %w[zú sú],
      ], MAX_VARIANTS, [word])
    end

    def if_hyperlemma(result)
      return result.hyperlemma if result.hyperlemma.nil? || result.hyperlemma.empty?

      yield result.hyperlemma
    end
  end
end
