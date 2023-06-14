# -*- coding: utf-8 -*-

require_relative "../galician_xiada/enclitics_processor_custom.rb"

class EncliticsProcessorCustom
  def initialize(sentence, dw, enclitics_hash)
    @sentence = sentence
    @dw = dw
    @enclitics_hash = enclitics_hash
  end

  def restore_source_form(verb_part, verb_tags, enclitic_part, enclitic_syllables_length, begin_alternative_token, end_alternative_token, token_from, token_to, token, prefix)
    final_recovery_words = Hash.new
    relevant_tokens = Array.new
    infos = @dw.get_enclitic_verb_roots_info(verb_part, verb_tags.split(" "))
    infos.each do |info|
      tag_value = info[0]
      lemma = info[1]
      hiperlemma = info[2]
      results = @dw.get_recovery_info(verb_part, tag_value, lemma, true)
      if results.empty?
        results = @dw.get_recovery_info(verb_part, tag_value, lemma, false)
      end
      if results.empty?
        STDERR.puts "WARNING: Reverse info for tag:#{tag_value} and lemma:#{lemma} not found. Searching for verb_part: #{verb_part}"
      end
      max_p_score = 0
      final_recovery_word = String.new(verb_part)
      final_recovery_tag = String.new(tag_value)
      final_recovery_lemma = String.new(lemma)
      final_recovery_hiperlemma = String.new(hiperlemma)
      final_recovery_log_b = -100 # To be changed ???
      results.each do |result|
        recovery_word = result[0]
        recovery_tag = result[1]
        recovery_lemma = result[2]
        recovery_hiperlemma = result[3]
        recovery_log_b = Float(result[4])
        # If there are several entries for the same tag and lemma, we
        # choose the word with the greater proximity score.
        p_score = proximity_score(recovery_word, verb_part)
        # STDERR.puts "p_score:#{p_score} recovert_word:#{recovery_word}, verb_part:#{verb_part}}"
        if p_score >= max_p_score
          max_p_score = p_score
          final_recovery_word = recovery_word
          final_recovery_tag = recovery_tag
          final_recovery_lemma = recovery_lemma
          final_recovery_hiperlemma = recovery_hiperlemma
          final_recovery_log_b = recovery_log_b
        end
      end
      if final_recovery_words[final_recovery_word] == nil
        new_token = Token.new(@sentence.text, final_recovery_word, :standard, token_from, token_to)
        new_token.qualifying_info = token.qualifying_info.clone
        final_recovery_words[final_recovery_word] = new_token
        begin_alternative_token.add_next(new_token)
        new_token.add_prev(begin_alternative_token)
        new_token.add_next(end_alternative_token)
        end_alternative_token.add_prev(new_token)
        relevant_tokens << new_token
      end
      final_recovery_words[final_recovery_word].add_tag_lemma_emission(final_recovery_tag, final_recovery_lemma, final_recovery_hiperlemma, final_recovery_log_b, false)
    end
    return relevant_tokens
  end

  protected

  def proximity_score(recovery_word, verb_part)
    recovery_word_wt = StringUtils.without_tilde(recovery_word)
    verb_part_wt = StringUtils.without_tilde(verb_part)
    score = 0
    (0..recovery_word.length - 1).each do |index|
      recovery_word_letter = recovery_word[index]
      recovery_word_letter_wt = recovery_word[index]
      if index < verb_part.length
        verb_part_letter = verb_part[index]
        verb_part_letter_wt = verb_part_wt[index]
        if recovery_word_letter == verb_part_letter
          score = score + 2
        elsif recovery_word_letter_wt == verb_part_letter_wt
          score = score + 1
        end
      else
        score = score - 1
      end
    end
    return score
  end
end
