require 'English'
require 'open3'

def syscall(*cmd)
  puts cmd
  stdout, stderr, status = Open3.capture3(*cmd)
  if status.success?
    return stdout.slice!(1..-(1 + $INPUT_RECORD_SEPARATOR.size)), status.success? # strip trailing eol
  else
    puts "ERROR: #{stdout}" unless stdout.empty?
    puts "ERROR: #{stderr}" unless stderr.empty?
    status.success?
  end
end
