data = IO.foreach(File.join(__dir__, 'bash_prompt.rb')).reject { |x|
	stripped = x.lstrip
	stripped.empty? || stripped.start_with?(?#)
}.join

data.gsub!(/(\\.{1})/) { |x| "\\#{x}" }
data.gsub!(?\t, '')
data.gsub!(?\r, "\\r")
data.gsub!('"', '\"')

c_code = data.lines.map { |slice| %Q(\t"#{slice.strip}\\n") }.join(?\n)
c_code

puts %Q(char *code() { return(\n#{c_code}\n);})
