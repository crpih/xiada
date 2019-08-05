# -*- coding: utf-8 -*-

while line = STDIN.gets
  line.chomp!
  puts line unless line =~ /VTP1P/ or line =~ /VTP3P/ or line =~ /VTP4S/ or line =~/DOAS/ or line =~/DONS/ or line=~/DOIS/
end

