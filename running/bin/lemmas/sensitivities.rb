# frozen_string_literal: true

module Lemmas
  module Sensitivities
    # Generates all possible variants of a word and concat them to the variants array.
    # For each equivalence group element found, it generates a variant per group element replacing the match with it.
    # For example, for the equivalence group [%w[a á], %w[A Á]] and the word 'a', it generates the variants 'a' and 'á'.
    # It raises an exception if the number of variants is greater than max_variants.
    def generate_variants!(word, group, max_variants, variants)
      regex = /#{group.map { |e| Regexp.escape(e) }.join('|')}/
      word.enum_for(:scan, regex).map { Regexp.last_match.offset(0) }.flat_map do |start, finish|
        group.each do |replacement|
          next if word[start...finish] == replacement
          raise 'Too many variants' if variants.size >= max_variants

          variants << word.dup.tap { |w| w[start...finish] = replacement }
        end
      end
      variants
    end

    # All equivalence groups are applied to the initial word.
    # This is useful for regular accents, since there is only one possible accent for each word.
    def independent_variants(equivalence_groups, max_variants, variants)
      (0...variants.size).each do |i|
        equivalence_groups.each { |g| generate_variants!(variants[i], g, max_variants, variants) }
      end
      variants
    end

    # Equivalence groups are applied until no new variants are generated.
    # This is useful for gemination, since there are multiple possible geminations for each word.
    def composed_variants(equivalence_groups, max_variants, variants)
      gi = 0
      new_variants = []
      loop do
        break if gi >= equivalence_groups.size

        group = equivalence_groups[gi]
        variants_size = variants.size
        variants.each { |v| generate_variants!(v, group, max_variants, new_variants) }

        variants.concat(new_variants).uniq! # Applying the same group to the same word can generate duplicates
        new_variants.clear # Clear the new variants for the next group
        raise 'Too many variants' if variants.size > max_variants

        gi += 1 if variants_size == variants.size # Advance to the next group only if no new variants were generated
      end
      variants
    end

    def suffix_variants(equivalence_groups, max_variants, variants)
      (0...variants.size).each do |i|
        word = variants[i]
        # Only one equivalence group can match: they must be disjoint
        equivalence_group = equivalence_groups.find { |suffixes| word.end_with?(*suffixes) }
        next unless equivalence_group

        word_suffix = equivalence_group.find { |suffix| word.end_with?(suffix) }
        base_word = word.delete_suffix(word_suffix)
        group_variants = equivalence_group.filter_map { |suffix| "#{base_word}#{suffix}" if word_suffix != suffix }
        raise 'Too many variants' if variants.size + group_variants.size > max_variants

        variants.concat(group_variants)
      end
      variants
    end

    def apply_variants(variant_functions, max_variants, variants)
      variant_functions.each { |f| f.(max_variants, variants) }
      variants
    end

    def tilde_variants(max_variants, variants)
      independent_variants([
                             %w[a á], %w[A Á],
                             %w[e é], %w[E É],
                             %w[i í], %w[I Í],
                             %w[o ó], %w[O Ó],
                             %w[u ú], %w[U Ú]
                           ], max_variants, variants)
    end
  end
end
