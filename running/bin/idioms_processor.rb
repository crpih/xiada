# -*- coding: utf-8 -*-
require_relative 'database_wrapper.rb'

class IdiomsProcessor
  # Nowadays this processor does not detect idioms which goes trow
  # alternatives. Bypassing until it occurs.

  def initialize(sentence, dw)
    @sentence = sentence
    @dw = dw
  end
  
  def process
    #puts "Searching start points..."
    possible_start_points = search_possible_start_points

    #puts "Seaching end_points..."
    end_points = search_end_points(possible_start_points)

    prev_to = nil
    possible_start_points.each_index do |index|
      possible_start_point = possible_start_points[index]
      #STDERR.puts "index:#{index} possible_start_point:#{possible_start_point[0].text}"
      from = possible_start_point[0]
      from_alternative = possible_start_point[1]
      # By now we use only the longest idiom
      end_point = end_points[index].last
      # STDERR.puts "end_point: #{end_point}"
      to = end_point[0]
      to_alternative = end_point[1]
      idiom = end_point[2]
      sure = end_point[3]

      unless to == nil or (prev_to != nil and from.from <= prev_to)
        #puts "*** IDIOM ***"
        #puts "from:#{from.text}"
        #puts "from_alternative: #{from_alternative}"
        #puts "from.from:#{from.from}"
        #puts "to: #{to.text}"
        #puts "to_alternative: #{to_alternative}"
        #puts "prev_to:#{prev_to}"
        #puts "idiom: #{idiom}"
        #puts "sure: #{sure}"
        #puts "*** /IDIOM ***"
      end

      # It could be an idiom inside another and situation change when processing the first one:
      # a a beira de --- beira de => Not regarded the second one by now
      unless to == nil or (prev_to != nil and from.from <= prev_to) or !from.nexts_ignored.empty?
        #puts "before join"
        join_idiom(from, from_alternative, to, to_alternative, idiom, sure)
        #puts "after join"
        prev_to = to.to
      end
    end
    #puts "process finished"
  end

  private

  def search_possible_start_points_alternative(token)
    # STDERR.puts "(search_possible_start_points_alternative) token:#{token.text}"
    possible_start_points = Array.new
    while token.token_type != :end_alternative
      idioms = @dw.get_multiword_match(token.text + " ")
      unless idioms.empty?
        #puts "possible_start_point_alternative: #{token.text}"
        possible_start_points << [token, true]
        # Second value of the pair indicates that the start_point is inside an alternative
      end
      token = token.next
    end
    return possible_start_points
  end

  def search_possible_start_points
    possible_start_points = Array.new
    token = @sentence.first_token
    while token.token_type != :end_sentence
      if token.token_type == :begin_sentence
        # STDERR.puts "BEGIN_SENTENCE"
        token = token.next
      elsif token.token_type == :end_alternative
        # STDERR.puts "END_ALTERNATIVE"
        token = token.next
      elsif token.token_type == :begin_alternative
        # STDERR.puts "BEGIN_ALTERNATIVE"
        token.nexts.keys.each do |token_aux|
          start_points_aux = search_possible_start_points_alternative(token_aux)
          possible_start_points.concat(start_points_aux)
        end
        while token.token_type != :end_alternative
          # STDERR.puts "END_ALTERNATIVE"
          token = token.next
        end
      elsif token.token_type == :standard
        # STDERR.puts "STANDARD token:#{token.text}"
        idioms = @dw.get_multiword_match(token.text + " ")
        unless idioms.empty?
          #puts "possible_start_point: #{token.text}"
          possible_start_points << [token, false]
          # Second value of the pair indicates that the start_point is outside an alternative
        end
        token = token.next
      end
    end
    return possible_start_points
  end

  def search_end_points_aux_alternative(token, substring)
    #puts "searching throw alternatives. token:#{token.text} type:#{token.token_type}"
    end_points = Array.new
    while token.token_type != :end_alternative
      idioms = @dw.get_multiword_full(substring + " " + token.text)
      unless idioms.empty?
        #puts "full. token:#{token.text} idiom: #{substring} #{token.text}"
        end_point = [token, true, substring + " " + token.text]
        # Second value indicates that the end_point is inside an alternative
        if @dw.is_idiom_sure?(idioms[0][0])
        # if Integer(idioms[0][4]) == 1 # sure field of first tuple
          end_point << true
        else
          end_point << false
        end
        end_points << end_point
      end
      idioms = @dw.get_multiword_match(substring + " " + token.text)
      if idioms.empty?
        break
      else
        substring = substring + " " + token.text
        token = token.next
      end
    end
    return end_points
  end
  
  def search_end_points_aux(token)
    #puts "\n\nsearch_end_points_aux token:#{token.text}"
    end_points = Array.new
    substring = token.text
    token = token.next
    while token.token_type != :end_sentence
      #STDERR.puts "substring: #{substring}"
      #STDERR.puts "token text:#{token.text} token type:#{token.token_type}"
      if token.token_type == :end_alternative
        token = token.next
      elsif token.token_type == :begin_alternative
        #STDERR.puts "begin_alternative"
        token.nexts.keys.each do |token_aux|
          end_points_aux = search_end_points_aux_alternative(token_aux, substring)
          end_points.concat(end_points_aux) unless end_points_aux.empty?
        end
        break
      elsif token.token_type == :standard
        if token.text != "."
          idioms = @dw.get_multiword_full(substring + " " + token.text)
        else
          idioms = @dw.get_multiword_full(substring + token.text)
        end
        #STDERR.puts "idioms.empty?:#{idioms.empty?}"
        #STDERR.puts "idioms:#{idioms}"
        unless idioms.empty?
          #STDERR.puts "end_point:#{token.text}"
          if token.text != "."
            end_point = [token, false, substring + " " + token.text]
          else
            end_point = [token, false, substring + token.text]
          end
          # Second value indicates that the end_point is outside an alternative
          if @dw.is_idiom_sure?(idioms[0][0])
          #if Integer(idioms[0][4]) == 1 # sure field of first tuple
            end_point << true
            #STDERR.puts "true"
          else
            end_point << false
            #STDERR.puts "false"
          end
          end_points << end_point
        end
        idioms = @dw.get_multiword_match(substring + " " + token.text)
        if idioms.empty?
          #puts "break"
          break
        else
          substring = substring + " " + token.text
          token = token.next
        end
      end
    end
    if end_points.empty?
      end_point = [nil, false, nil, nil]
      end_points << end_point
    end
    return end_points
  end
  
  def search_end_points(possible_start_points)
    end_points = Array.new
    possible_start_points.each do |possible_start_point|
      token = possible_start_point[0]
      #STDERR.puts "Searching end point for token:#{token.text}..."
      end_points_aux = search_end_points_aux(token)
      #STDERR.puts "End_points_aux:#{end_points_aux}"
      end_points << end_points_aux
    end
    return end_points
  end
  
  def join_idiom(from, from_alternative, to, to_alternative, idiom, sure)
    # STDERR.puts "Joining idiom from:#{from.text} (alternative:#{from_alternative}) to:#{to.text} (alternative:#{to_alternative}) idiom:#{idiom} sure:#{sure}"
    if sure
      join_sure_idiom(from, from_alternative, to, to_alternative, idiom)
    else
      join_unsure_idiom(from, from_alternative, to, to_alternative, idiom)
    end
  end

  def remove_alternatives(middle_token)
    first_alternative_token = middle_token
    token = first_alternative_token
    while token.token_type != :begin_alternative
      first_alternative_token = token
      token = token.prev
    end
    before_begin_alternative_token = token.prev
    #puts "first_alternative_token: #{first_alternative_token.text}"
    #puts "before_begin_alternative_token: #{before_begin_alternative_token.text}"
    token = middle_token
    while token.token_type != :end_alternative
      last_alternative_token = token
      token = token.next
    end
    after_end_alternative_token = token.next
    #puts "last_alternative_token: #{last_alternative_token.text}"
    #puts "after_end_alternative_token: #{after_end_alternative_token.text}"
    
    before_begin_alternative_token.reset_nexts
    first_alternative_token.reset_prevs
    before_begin_alternative_token.add_next(first_alternative_token)
    first_alternative_token.add_prev(before_begin_alternative_token)
    
    after_end_alternative_token.reset_prevs
    last_alternative_token.reset_nexts
    after_end_alternative_token.add_prev(last_alternative_token)
    last_alternative_token.add_next(after_end_alternative_token)
  end

  def join_sure_idiom (from, from_alternative, to, to_alternative, idiom)
    # STDERR.puts "(join_sure_idiom) from: #{from.text} alternative:#{from_alternative} to:#{to.text} alternative:#{to_alternative}"
    before_from_token = from.prev
    after_to_token = to.next

    idiom_token = Token.new(@sentence.text, idiom, :standard, from.from, to.to)
    idiom_token.nexts_ignored = to.nexts_ignored.dup
    # idiom_token.ignored_content_info = from.ignored_content_info.dup if idiom_token.ignored_content_info
    idiom_token.qualifying_info = from.qualifying_info.clone

    if from_alternative
      remove_alternatives(from)
      before_from_token = from.prev
    end

    #puts "before_from_token:#{before_from_token.text}"
    before_from_token.reset_nexts
    before_from_token.add_next(idiom_token)
    idiom_token.add_prev(before_from_token)

    if to_alternative
      remove_alternatives(to)
      after_to_token = to.next
    end

    #puts "after_to_token:#{after_to_token.text}"
    after_to_token.reset_prevs
    after_to_token.add_prev(idiom_token)
    idiom_token.add_next(after_to_token)

    # Solving idioms which starts or ends with a contraction not
    # included inside the idiom.
    token = idiom_token.next
    while token.token_type == :standard and token.to == idiom_token.to
      token.change_from(idiom_token.from)
      token = token.next
    end

    token = idiom_token.prev
    while token.token_type == :standard and token.from == idiom_token.from
      token.change_to(idiom_token.to)
      token = token.prev
    end

    add_qualifying_info(idiom_token, from, to)
    # add_ignored_content_info(idiom_token, from, to)
    add_nexts_ignored(idiom_token, to)

  end
  
  def add_qualifying_info(new_token, from, to)
    token = from
    while token != to
      token.qualifying_info.keys.each do |info|
        new_token.add_qualifying_info("#{info}")
      end
      token = token.next
    end
    # STDERR.puts "new_token.qualifying_info: #{new_token.qualifying_info}"
  end

  def add_ignored_content_info(new_token, from, to)
    #if to.ignored_content_info
    #  new_token.ignored_content_info = Array.new
    #  to.ignored_content_info.each do |info|
    #    new_token.ignored_content_info << "#{info}"
    #  end
    #end

    token = from
    while token != to
      if token.ignored_content_info
        new_token.ignored_content_info = Array.new unless new_token.ignored_content_info
        token.ignored_content_info.each do |info|
          new_token.ignored_content_info << "#{info}"
        end
      end
      token = token.next
    end
    if token.ignored_content_info
      new_token.ignored_content_info = Array.new unless new_token.ignored_content_info
      token.ignored_content_info.each do |info|
        new_token.ignored_content_info << "#{info}"
      end
    end
    # STDERR.puts "new_token.ignored_content_info: #{new_token.ignored_content_info}"
  end

  def add_nexts_ignored(new_token, to)
    new_token.nexts_ignored = to.nexts_ignored.dup
    # STDERR.puts "new_token.nexts_ignored: #{new_token.nexts_ignored}"
  end

  def join_unsure_idiom (from, from_alternative, to, to_alternative, idiom)
    # STDERR.puts "(join_unsure_idiom) from: #{from.text} alternative:#{from_alternative} to:#{to.text} alternative:#{to_alternative}"
    beyond_from = from.prev
    beyond_to = to.next

    new_token = Token.new(@sentence.text, idiom, :standard, from.from, to.to)

    start_token = Token.new(@sentence.text, nil, :begin_alternative, new_token.from, new_token.to)
    end_token = Token.new(@sentence.text, nil, :end_alternative, new_token.from, new_token.to)
    start_token.add_next(new_token)
    new_token.add_prev(start_token)
    # Solving idioms which begin with a contraction
    next_token = new_token
    unless from_alternative
      while beyond_from.token_type == :standard and beyond_from.from == new_token.from
        token = beyond_from.deep_copy_reset_links
        token.change_to(new_token.to)
        next_token.reset_prevs
        next_token.add_prev(token)
        token.add_next(next_token)
        next_token = token
        from = beyond_from
        beyond_from = beyond_from.prev
      end
      next_token.add_prev(start_token)
      start_token.reset_nexts
      start_token.add_next(next_token)
      beyond_from = beyond_from.prev if beyond_from.token_type == :begin_alternative
    else
      # Similar for the begining of alternative if idiom starts inside it
      token = from.prev
      while token.token_type == :standard
        token_aux = token.deep_copy_reset_links
        next_token.reset_prevs
        next_token.add_prev(token_aux)
        token_aux.add_next(next_token)
        next_token = token_aux
        token = token.prev
      end
      from = token
      beyond_from = from.prev
      next_token.add_prev(start_token)
      start_token.reset_nexts
      start_token.add_next(next_token)
    end

    # Solving idioms which finish with a contraction.
    prev_token = new_token
    unless to_alternative
      while beyond_to.token_type == :standard and beyond_to.to == new_token.to
        token = beyond_to.deep_copy_reset_links
        token.change_from(new_token.from)
        prev_token.reset_nexts
        prev_token.add_next(token)
        token.add_prev(prev_token)
        prev_token = token
        to = beyond_to
        beyond_to = beyond_to.next
      end
      prev_token.add_next(end_token)
      end_token.reset_prevs
      end_token.add_prev(prev_token)
      beyond_to = beyond_to.next if beyond_to.token_type == :end_alternative
    else
      # Similar for the ending of alternative if idiom ends inside it
      token = beyond_to
      while token.token_type == :standard
        token_aux = token.deep_copy_reset_links
        token_aux.change_from(new_token.from)
        prev_token.reset_nexts
        prev_token.add_next(token_aux)
        token_aux.add_prev(prev_token)
        prev_token = token_aux
        token = token.next
      end
      to = token
      beyond_to = to.next
      prev_token.add_next(end_token)
      end_token.reset_prevs
      end_token.add_prev(prev_token)
    end

    add_qualifying_info(new_token, from, to)
    # add_ignored_content_info(new_token, from, to)
    add_nexts_ignored(new_token, to)

    # @sentence.print_from_token(start_token)
    # @sentence.print_reverse_from_token(end_token)
    add_ways(start_token, end_token, from, from_alternative, to, to_alternative)

    # We connect the new structure in the sentence
    beyond_from.reset_nexts
    beyond_from.add_next(start_token)
    start_token.add_prev(beyond_from)
    beyond_to.reset_prevs
    beyond_to.add_prev(end_token)
    end_token.add_next(beyond_to)
  end

  def add_ways(start_token, end_token, from, from_alternative, to, to_alternative)
    #puts "before add_ways_recursive: from:#{from.text} type:#{from.token_type} to:#{to.text} type:#{to.token_type}"
    add_ways_recursive(start_token, end_token, from, from_alternative, to, to_alternative, start_token, from, 1)
  end
  
  def add_ways_recursive(start_token, end_token, from, from_alternative, to, to_alternative, prev_token, token, way)
    #puts "\nadd_ways_recursive: prev_token:#{prev_token.text} type:#{prev_token.token_type} token:#{token.text} type:#{token.token_type} way:#{way}"
    if token != to
      if token.token_type == :standard
        new_token = token.deep_copy_reset_links
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        #puts "connecting token:#{new_token.text} to prev token:#{prev_token.text} type:#{prev_token.token_type}"
        prev_token = new_token
        add_ways_recursive(start_token, end_token, from, from_alternative, to, to_alternative, prev_token, token.next, way)
      elsif token.token_type == :begin_alternative
        way_aux = 1
        token.nexts.keys.each do |token_aux|
          #puts "way: #{way_aux}"
          if prev_token != start_token and way_aux != 1
            token_aux2 = prev_token
            first_alternative_token = nil
            while token_aux2.token_type != :begin_alternative
              first_alternative_token = token_aux2
              token_aux2 = token_aux2.prev
            end
            prev_token = copy_way(start_token, first_alternative_token, prev_token)
          end
          add_ways_recursive(start_token, end_token, from, from_alternative, to, to_alternative, prev_token, token_aux, way_aux)
          way_aux = way_aux + 1
        end
      elsif token.token_type == :end_alternative
        add_ways_recursive(start_token, end_token, from, from_alternative, to, to_alternative, prev_token, token.next, 1)
      end
    else
      if to_alternative or token.token_type != :standard
        prev_token.add_next(end_token)
        end_token.add_prev(prev_token)
      else
        new_token = token.deep_copy_reset_links
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        new_token.add_next(end_token)
        end_token.add_prev(new_token)
      end
    end
  end


  def copy_way(start_token, first_token, last_token)
    #puts "copying way from first_token:#{first_token.text} type:#{first_token.token_type} to last_token:#{last_token.text} type:#{last_token.token_type}"
    token = first_token
    prev_token = start_token
    while token != last_token
      #puts "copying token: #{token.text} type:#{token.token_type}, prev_token: #{prev_token.text} type:#{prev_token.token_type}"
      new_token = token.deep_copy_reset_links
      prev_token.add_next(new_token)
      new_token.add_prev(prev_token)
      prev_token = new_token
      token = token.next
    end

    #puts "copying token: #{token.text} type:#{token.token_type}, prev_token: #{prev_token.text} type:#{prev_token.token_type}"
    new_token = token.deep_copy_reset_links
    prev_token.add_next(new_token)
    new_token.add_prev(prev_token)
    return (new_token)
  end
end
  
