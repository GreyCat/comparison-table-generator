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
		@out.puts "\t<th>#{desc}</th>"
		cols.each { |c|
			refs_layout = if c[:refs]
				c[:refs].map { |x|
					"<a class=\"reflink\" href=\"#{x.chomp}\">?</a>"
				}.join
			else
				''
			end

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

			@out.puts "\t<td#{css_layout}>#{refs_layout}#{s}</td>"
		}
		@out.puts '</tr>'
	end
end
