# -*- coding: utf-8 -*-
require 'socket'

# main
hostname = 'localhost'
port = ARGV[0]
if (ARGV.length!=1)
  puts "ruby SocketTest.rb <port>"
  exit(1)
end

while line = STDIN.gets
  socket = TCPSocket.new(hostname, port)
  line.chomp
  socket.puts(line)
  result = socket.gets.gsub!(/\t\t/,"\n")
  puts result
  socket.close
end
