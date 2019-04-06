# -*- coding: utf-8 -*-

while line=STDIN.gets
  line.chomp!
  unless line.empty?
    word, tag, lemma = line.split ("\t")
    word, tag, lemma = line.split ("\t")
    if word == nil or tag == nil or lemma == nil
      puts "ERR: #{line}"
    else
      word.strip!
      tag.strip!
      lemma.strip!
      if word.empty? or tag.empty? or lemma.empty?
        puts "ERR: #{line}"
      end
    end
  end
end

