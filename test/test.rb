#!/usr/bin/env ruby

require 'fileutils'
require 'tmpdir'

# Time an operation
def time(n = nil)
  t1 = Time.now
  yield
  t2 = Time.now

  diff = t2 - t1
  rate = (n.to_f / diff).round(2) if n
  puts "#{(n || 0).group} in #{diff.group}s, Rate: #{(rate || 0).group}/s"
end

# Profile a block using ruby-prof
def profile 
  require 'ruby-prof'
  RubyProf.start
  yield()
  result = RubyProf.stop

  # Print a flat profile to text
  printer = RubyProf::GraphPrinter.new(result)
  # printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end




require 'dbhash'

tmp = Dir.mktmpdir

puts "Using #{tmp}"
dh  = DBHash::DiskHash.new(tmp)


100.times do |n|
  dh["Key#{n}"] = "Value#{n}"
end

dh.each do |k, v|
  puts "=> #{v}"
end



# Remove temp
dh.close
puts "Removing #{tmp}"
FileUtils.rm_r(tmp)

