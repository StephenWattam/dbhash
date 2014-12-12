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


10.times do |n|
  dh["Key"] = "Value#{n}"
end
10.times do |n|
  dh["Key2"] = "2Value#{n}2"
end
10.times do |n|
  dh["Key3"] = "3Value#{n}3"
end


puts "Each write operation:"
dh.each do |k, v|
  puts "[#{k}] => #{v}"
end

puts "Each part in the 'Key' chain:"
dh.each_for("Key") do |v|
  puts "#{v}"
end
puts "First/last for 'Key': #{dh.first_for("Key")}, #{dh.last_for("Key")}"
puts "length: #{dh.length_for("Key")}"


# Remove temp
dh.close
puts "Removing #{tmp}"
FileUtils.rm_r(tmp)

