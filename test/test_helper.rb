# $LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path("../../running/bin", __FILE__)

# puts $LOAD_PATH
require 'minitest/spec'
require "minitest/autorun"
