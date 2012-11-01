# -*- coding: utf-8 -*-

require 'erb'

class HTMLTableGenerator
	def initialize(gen, style, out)
		@gen = gen
		@style = style
		@out = out
	end

	def process_rhtml(filename)
		@out << ERB.new(File.open("#{@style}/#{filename}").read).result(@gen.get_binding)
	end

	def global_header
		process_rhtml('global_header.rhtml')
	end

	def global_footer
		process_rhtml('global_footer.rhtml')
	end

	def row_header(depth, desc)
		@out.puts <<__EOF__
<tr class="header#{depth}">
	<th colspan="#{@gen.topics.length + 1}">#{desc}</th>
</tr>
__EOF__
	end

	def row(desc, cols)
		@out.puts '<tr class="data">'
		@out.puts "\t<th class=\"cell\">#{desc}</th>"
		cols.each { |c|
			s = c[:data] || '?'

			# Special tags that influence cell styles: must be come first
			css_class = nil
			case s
			when /^<yes\s*\/?>(.*)$/mi
				css_class = 'cell_yes'
				s = "<div class=\"cell_symbol\">\u2611</div>\n#{$1}"
			when /^<no\s*\/?>(.*)$/mi
				css_class = 'cell_no'
				s = "<div class=\"cell_symbol\">\u2610</div>\n#{$1}"
			when /^<na\s*\/?>(.*)$/mi
				css_class = 'cell_na'
				s = "<div class=\"cell_symbol\">N/A</div>\n#{$1}"
			end
			css_layout = css_class ? " class=\"#{css_class}\"" : ''

			@out.puts <<__EOF__
	<td#{css_layout}>
		<a class=\"cell-link\" href=\"#{c[:link]}\">
			<div class=\"cell\">#{s}</div>
		</a>
	</td>
__EOF__
		}
		@out.puts '</tr>'
	end
end
