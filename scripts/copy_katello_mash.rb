#!/usr/bin/env ruby

if ARGV.length != 2
  puts "Please specify the version to copy from and the version to copy to, e.g. ./copy_katello_mash.rb 2.2 2.3"
  exit 1
end

from_version = ARGV[0]
to_version = ARGV[1]

Dir["/etc/mash/katello-#{from_version}*"].each do |file|
  content = File.read(file)
  content.gsub!(from_version, to_version)
  File.open(file.gsub(from_version, to_version), 'w') do |to_file|
    to_file.puts(content)
  end
end

