data = IO.read(File.join(__dir__, 'bash_profile.rb'))

data.gsub!(/(\\.{1})/) { |x| "\\#{x}" }
data.gsub!(?\t, "\\t")
data.gsub!(?\r, "\\r")
data.gsub!('"', '\"')

puts data.lines.map { |slice| %Q(\t"#{slice.strip}\\n") }.join(?\n)
