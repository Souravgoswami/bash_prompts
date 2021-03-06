###### CPrompt from C File ######
PWD = CPrompt.get_pwd
hostname = CPrompt.get_hostname
logname = CPrompt.get_logname
current_time = CPrompt.get_current_time
children = CPrompt.count_files

###### Test ######
#~ PWD = 'pwd'
#~ hostname = 'hostname'
#~ logname = 'logname'
#~ current_time = Time.now
#~ children = 50

TMPFILE = "/tmp/bash_prompt_#{logname}.lock"

class String
	# Fast conversion to RGB when Integer is passed.
	# For example: 0xffffff for white,
	# 0x000000 or 0x0 for black, 0x00aa00 for deep green
	# 0xff50a6 for pink, 0xff5555 for light red, etc.
	#
	# Similarly:
	# (255 * 256 * 256) + (255 * 256) + (255) => 0xffffff
	# (0 * 256 * 256) + (0 * 256) + 0 => 0x0
	# (255 * 256 * 256) + (85 * 256) + 85 => #ff5555
	# (85 * 256 * 256) + (85 * 256) + 255 => #5555ff
	# (255 * 256 * 256) + (170 * 256) + 0 => 0xffaa00
	# (0 * 256 * 256) + (170 * 256) + 0 => 0x00aa00
	def hex_to_rgb(hex)
		return [
			255 & hex >> 16,
			255 & hex >> 8,
			255 & hex
		] if hex.is_a?(Integer)

		# Duplicate colour, even if colour is nil
		# This workaround is for Ruby 2.0 to Ruby 2.2
		# Which won't allow duplicate nil.
		colour = hex && hex.dup.to_s || ''
		colour.strip!
		colour.downcase!
		colour[0] = ''.freeze if colour[0] == ?#.freeze

		# out of range
		oor = colour.scan(/[^a-f0-9]/)

		unless oor.empty?
			invalids = colour.chars.map { |x|
				oor.include?(x) ? "\e[1;31m#{x}\e[0m" : x
			}.join

			raise ArgumentError, "\e[0mHex Colour \e[1m##{invalids} is Out of Range\e[0m"
		end

		clen = colour.length

		if clen == 3
			colour.chars.map { |x| x.<<(x).to_i(16) }
		elsif clen == 6
			colour.chars.each_slice(2).map { |x| x.join.to_i(16) }
		else
			sli = clen > 6 ? 'too long'.freeze : clen < 3 ? 'too short'.freeze : 'invalid'.freeze
			raise ArgumentError, "Invalid Hex Colour ##{colour} (length #{sli})"
		end
	end

	##
	# = gradient(*arg_colours, bg: false, exclude_spaces: true, bold: false, blink: false)    # => string or nil
	#
	# Prettifies your string by adding gradient colours.
	#
	# This method accept a lot of colours. For example:
	#
	# 1. puts "Hello".gradient('#f55', '#55f')
	# This will add #f55 (red) to #55f (blue) gradient colours to your texts.
	#
	# 2. puts "Hello\nWorld".gradient('#f55', '#55f')
	# This will add #f55 (red) to #55f (blue) gradient colours to your texts, spanning multiple lines.
	#
	# 3. puts "Hello\nWorld!\nColours\nare\nrotated here".gradient('f55','55f', '3eb' 'ff5')
	# This will add #ff5555 (red) to #5555ff (blue) gradient colours to the first line,
	# 5555ff to 33eebb colour to the 2nd line,
	# 33eebb to ffff55 to the third line
	# And then back to ffff55 to ff5555 to the fourth line,
	# And it will continue to rotate between these colours.
	#
	# To stop rotating, just don't give more than two arguments to this method.
	#
	# Passing blocks is also optional, and is handy for animating text. For example:
	#    "Hello\nWorld!\nColours\nare\nrotated here".gradient('f55','55f', '3eb' 'ff5', bg:true) { |x| print x ; sleep 0.05 }
	#
	# This will pass the values to the block itself, and will draw the colourful text slowly.
	# Passing block will return nil from the method because the values will be passed to the block variable instead.
	#
	# Adding the option bg will change the background colour, but will keep the foreground colour
	# defined in the terminal settings.
	#
	# The option exclude_spaces, is expected to set either true or false.
	# By default it's set to true.
	# Enabling this option will not waste colours on white-spaces.
	# White spaces only include: \s, \t
	#
	# Please do note that \u0000 and \r in the middle of the string will not be
	# counted as a white space, but as a character instead.
	# This is because \r wipes out the previous characters, and using \u0000 in
	# a string is uncommon, and developers are requested to delete
	# \u0000 from string if such situations arise.
	#
	# The option bold makes texts bold, but it also makes the string bigger.
	# Set bold to anything truthy or falsey, but better just go with true and false or nil
	#
	# The option blink makes the texts blink on supported terminals.
	# Set blink to anything truthy or falsey, but better just go with true and false or nil
	def gradient(*arg_colours,
		exclude_spaces: true,
		bg: false,
		bold: false,
		italic: false,
		underline: false,
		blink: false,
		strikethrough: false,
		double_underline: false,
		overline: false
		)

		space, tab = ?\s.freeze, ?\t.freeze

		block_given = block_given?
		temp = ''
		flatten_colours = arg_colours.flatten

		# Create the styling here rather than creating it in the each_line loop
		# We also make it a bit different, rather than using \e[1m\e[5m, we will do
		# \e[1;5m to save the number of characters spit out by this method
		style = nil

		if bold || italic || underline || blink || strikethrough || double_underline || overline
			style = "\e["

			style << '1;'.freeze if bold
			style << '3;'.freeze if italic
			style << '4;'.freeze if underline
			style << '5;'.freeze if blink
			style << '9;'.freeze if strikethrough
			style << '21;'.freeze if double_underline
			style << '53;'.freeze if overline

			style.chop!
			style << ?m.freeze
		end

		raise ArgumentError, "Wrong numeber of colours (given #{flatten_colours.length}, expected minimum 2)" if flatten_colours.length < 2
		raise ArgumentError, "Given argument for colour is neither a String nor an Integer" if flatten_colours.any? { |x| !(x.is_a?(String) || x.is_a?(Integer)) }

		all_rgbs = flatten_colours.map!(&method(:hex_to_rgb))

		yield style if block_given && style

		# r, g, b => starting r, g, b
		# r2, g2, b2 => stopping r, g, b
		r, g, b = *all_rgbs[0]
		r2, g2, b2 = *all_rgbs[1]
		rotate = all_rgbs.length > 2

		init = bg ? 48 : 38

		lines do |c|
			temp << style if style

			_r, _g, _b = r, g, b
			chomped = !!c.chomp!(''.freeze)

			len = c.length
			n_variable = exclude_spaces ? c.delete("\t\s".freeze).length : len
			n_variable -= 1
			n_variable = 1 if n_variable < 1

			# colour operator, colour value
			#
			# r_op, g_op, b_op are also flags to determine
			# if the r, g, and b values respectively should change or not
			# For example, if the given blues are equal, the b_op is nil
			# So it won't change the colour in the ouput
			r_op = r_val  = nil
			g_op = g_val = nil
			b_op = b_val = nil

			if r2 > r
				r_op, r_val = :+, r2.-(r)./(n_variable.to_f)
			elsif r2 < r
				r_op, r_val = :-, r.-(r2)./(n_variable.to_f)
			end

			if g2 > g
				g_op, g_val = :+, g2.-(g)./(n_variable.to_f)
			elsif g2 < g
				g_op, g_val = :-, g.-(g2)./(n_variable.to_f)
			end

			if b2 > b
				b_op, b_val = :+, b2.-(b)./(n_variable.to_f)
			elsif b2 < b
				b_op, b_val = :-, b.-(b2)./(n_variable.to_f)
			end

			# To avoid the value getting adding | subtracted from the initial character
			_r = _r.send(r_op, r_val * -1) if r_op
			_g = _g.send(g_op, g_val * -1) if g_op
			_b = _b.send(b_op, b_val * -1) if b_op

			i = -1
			while (i += 1) < len
				_c = c[i]

				if !exclude_spaces || (_c != space && _c != tab)
					_r = _r.send(r_op, r_val) if r_op
					_g = _g.send(g_op, g_val) if g_op
					_b = _b.send(b_op, b_val) if b_op
				end

				r_to_i = _r.to_i
				g_to_i = _g.to_i
				b_to_i = _b.to_i

				clamped_r = r_to_i < 0 ? 0 : r_to_i > 255 ? 255 : r_to_i
				clamped_g = g_to_i < 0 ? 0 : g_to_i > 255 ? 255 : g_to_i
				clamped_b = b_to_i < 0 ? 0 : b_to_i > 255 ? 255 : b_to_i

				ret = "\e[#{init};2;#{clamped_r};#{clamped_g};#{clamped_b}m#{_c}"

				# if block_given
					# yield ret
				# else
					temp << ret
				# end
			end

			ret = if !c.empty?
				chomped ? "\e[0m\n".freeze : "\e[0m".freeze
			elsif chomped
				?\n.freeze
			end

			temp << ret

			if rotate
				all_rgbs.rotate!
				r, g, b = all_rgbs[0]
				r2, g2, b2 = all_rgbs[1]
			end
		end

		temp
	end

	##
	# = multi_gradient(*n_arg_colours, bg: false, exclude_spaces: true, bold: false, blink: false)    # => string or nil
	#
	# Accepts n number of colours. Example:
	#    'Hello world this is multi_gradient()'.multi_gradient('3eb', '55f', 'f55', 'fa0')
	#
	# In this example, multi_gradient() paints the string with 4 colours in one line.
	#
	# It Splits up a string with the Calls String#gradient() with the given number of colours
	# So each call to multi_gradient() involves many calls to String#gradient().
	# Hence it's slower than String#gradient()
	def multi_gradient(*colours,
		exclude_spaces: true,
		bg: false,
		bold: false,
		italic: false,
		underline: false,
		blink: false,
		strikethrough: false,
		double_underline: false,
		overline: false,
		&block
		)

		len = colours.length
		raise ArgumentError, "Minimum two colours are required, given #{len}" if len < 2

		div = len - 1
		div_1 = div - 1
		ret = ''
		block_given = block_given?

		params = {
			exclude_spaces: exclude_spaces,
			bg: bg,
			bold: bold,
			italic: italic,
			underline: underline,
			blink: blink,
			strikethrough: strikethrough,
			double_underline: double_underline,
			overline: overline,
		}

		lines { |l|
			_len = l.length

			len, c = _len./(div.to_f).round, colours.dup
			counter, i, j = -1, -1, 0
			ch = ''

			while x = l[i += 1] do
				counter += 1

				# colour % len == 0 is very slow approach
				if counter == len && j < div_1
					counter, j = 0, j + 1
					ret << ch.gradient(c[0], c[1], **params)
					c.rotate!
					ch.clear
				end

				ch << x
			end

			ret << ch.gradient(c[0], c[1], **params)
		}

		ret
	end
end

c = [
	0x00c0ff, 0xffff40, 0xff8359,
	0x59c2ff, 0x1270e3, 0x15eded,
	0x029cf5, 0xff7cce,
	0xf5317f, 0xb122e5
]

File.open(TMPFILE, 'w').write('0') rescue nil unless File.exist?(TMPFILE)
value = File.read(TMPFILE).to_i % c.length rescue nil
File.open(TMPFILE, 'w').write(value.+(1).to_s) rescue nil
c.rotate!(value)

print %Q(\u256d\u2504\u2504[#{logname}\u02d0\u02d0#{hostname}]\u2505).multi_gradient(c.shift, c.shift, c.shift) <<
	%Q([#{PWD}]).multi_gradient(c.shift, c.shift, c.shift, bold: true) <<
	%Q(\u2505[#{children} item#{children == 1 ? '' : 's'}]).multi_gradient(c.shift, c.shift) <<
	%Q(\u2505[#{current_time}]).multi_gradient(c.shift, c.shift) <<
	%Q(\n\u2570\u2500\u2500\u257c\u2b9a\s)
