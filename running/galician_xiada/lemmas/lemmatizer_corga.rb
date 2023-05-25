# frozen_string_literal: true
require_relative '../../bin/lemmas/query'
require_relative '../../bin/lemmas/result'
require_relative 'utils'
require_relative 'auto_rule'
require_relative 'isimo_rule'
require_relative 'mente_rule'
require_relative 'inho_rule'
require_relative 'ex_rule'
require_relative 'ex_proper_rule'
require_relative 'meta_rule'
require_relative 'etno_rule'
require_relative 'macro_rule'
require_relative 'micro_rule'
require_relative 'xeo_rule'
require_relative 'multi_rule'
require_relative 'tele_rule'

module Lemmas
  class LemmatizerCorga
    include Utils

    module ClassMethods
      def lemmatize(word, _tags)
        @lemmatizer ||= LemmatizerCorga.new(@dw, seseo: !ENV['XIADA_SESEO'].nil?)
        result = @lemmatizer.call(word)
        result&.any? ? result.map { |r| [r.tag, r.lemma, r.hyperlemma, r.log_b] } : []
      end

      # Function which is called before accessing emission frequencies for verbs with enclitics pronouns.
      def lemmatize_verb_with_enclitics(left_part)
        #STDERR.puts "lemmatize_verb_with_enclitics: #{left_part}"
        # gh treatment
        if left_part =~ /gh/
          if left_part =~ /gh[aou]/
            new_left_part = left_part.gsub(/gh/,'g')
            return new_left_part
          elsif left_part =~/gh[ei]/
            new_left_part = left_part.gsub(/gh/,'gu')
            return new_left_part
          end
          # auto treatment
        elsif left_part =~ /^autorr/
          new_left_part = left_part.gsub(/^autor/,'')
          return new_left_part
        elsif left_part =~ /^auto-?/
          new_left_part = left_part.gsub(/^auto-?/,'')
          return new_left_part
        end
        left_part
      end

      # Function to tranform the word part when restoring a verb form with enclitics.
      def lemmatize_verb_with_enclitics_reverse_word(original_left_part, left_part)
        #STDERR.puts "original_left_part:#{original_left_part}, left_part:#{left_part}"
        # gh treatment
        if original_left_part =~ /gh/
          if left_part =~ /gh[aou]/
            new_left_part = left_part.gsub(/gh/,'g')
            return new_left_part
          elsif left_part =~/gh[ei]/
            new_left_part = left_part.gsub(/gh/,'gu')
            return new_left_part
          end
          # auto treatment
        elsif original_left_part =~/^autorr/
          new_left_part = left_part.gsub(/^(.)/,'autor\1')
          return new_left_part unless new_left_part =~ /^autor?auto/
        elsif original_left_part =~/^(auto-?)/
          new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
          return new_left_part unless new_left_part =~ /^autor?auto/
        end
        left_part
      end

      # Function to tranform the lemma part when restoring a verb form with enclitics.
      def lemmatize_verb_with_enclitics_reverse_lemma(original_left_part, left_part)
        if original_left_part =~/^(auto-?)/
          new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
          return new_left_part unless new_left_part =~ /^autor?auto/
        end
        left_part
      end

      # Function to tranform the hiperlemma part when restoring a verb form with enclitics.
      def lemmatize_verb_with_enclitics_reverse_hiperlemma(original_left_part, left_part)
        if original_left_part =~/^(auto-?)/
          new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
          return new_left_part  unless new_left_part =~ /^autor?auto/
        end
        left_part
      end

      # Function which replace a vowel by the corresponding tilde one.
      # position is the vowel order from the end.
      def set_tilde(word, position)
        characters = word.each_grapheme_cluster.to_a
        vowel_positions = characters.each_with_index
                                    .select { |c, _| %w[a e i o u á é í ó ú].include?(c) }
                                    .map(&:last)
        if position <= vowel_positions.size
          vowel_index = vowel_positions[-position]
          characters[vowel_index] = "#{characters[vowel_index]}\u0301".unicode_normalize
          characters.join
        else
          return word
        end
      end
    end

    def initialize(database_wrapper, gheada: true, seseo: false)
      @dw = database_wrapper
      @gheada = gheada
      @seseo = seseo
      @tags = @dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }

      @mente_rule = MenteRule.new(@tags)
      @auto_rule = AutoRule.new(@tags)
      @isimo_rule = IsimoRule.new(@tags)
      @inho_rule = InhoRule.new(@tags)
      @ex_rule = ExRule.new(@tags)
      @ex_proper_rule = ExProperRule.new(@tags)
      @meta_rule = MetaRule.new(@tags)
      @etno_rule = EtnoRule.new(@tags)
      @macro_rule = MacroRule.new(@tags)
      @micro_rule = MicroRule.new(@tags)
      @xeo_rule = XeoRule.new(@tags)
      @multi_rule = MultiRule.new(@tags)
      @tele_rule = TeleRule.new(@tags)
    end

    def call(word)
      gheada_queries(Query.new(nil, word, @tags)) do |q|
        seseo_queries(q) do |q|
          [
            *@auto_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@ex_proper_rule.(q) do |q|
              proper_noun(q)
            end,
            *@ex_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@meta_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@etno_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@macro_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@micro_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@xeo_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@multi_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@tele_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *suffix_rules(q),
            # LemmatizerCorga#lemmatizer won't be called if the term exists literally
            # So this is useful only for gheada variants: gherra => guerra and ghitarra => guitarra
            *find(q)
          ]
        end
      end
    end

    private

    def gheada_queries(query)
      return yield query unless @gheada

      gheada_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def seseo_queries(query)
      return yield query unless @seseo

      seseo_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def suffix_rules(query)
      [
        *@mente_rule.(query) { |qa| find_guesser('mente', qa) },
        *@isimo_rule.(query) { |qa| find(qa) },
        *@inho_rule.(query) { |qa| find(qa) },
      ]
    end

    def find(query)
      @dw.get_emissions_info(query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @dw.get_guesser_result("'#{suffix}'", query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def proper_noun(query)
      [Result.new(query, 'Sp00', query.word, query.word, 0.0)]
    end
  end
end
