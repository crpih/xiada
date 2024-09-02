require_relative 'tag_text'

text = ARGV.join(" ")
tag_text(text, nil).each do |t|
  puts "#{t[:token]}\t#{t[:tag]}\t#{t[:lemma]}\t#{t[:hiperlemma]}\t#{text[t[:start]..t[:finish]]}"
end
