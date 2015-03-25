require 'English'
require 'open3'

def syscall(*cmd)
  stdout, stderr, status = Open3.capture3(*cmd)
  if status.success?
    stdout.slice!(0..-(1 + $INPUT_RECORD_SEPARATOR.size)) # strip trailing eol
  else
    puts "ERROR: #{stderr}"
  end
end
