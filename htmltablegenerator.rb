class HTMLTableGenerator
	def initialize(gen, out)
		@gen = gen
		@out = out
	end

	def global_header
		@out.puts <<__EOF__
<!DOCTYPE html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
	<title>#{@gen.global_name}</title>
	<meta name="description" content="">
	<meta name="viewport" content="width=device-width">

	<link rel="stylesheet" href="css/normalize.css">
	<link rel="stylesheet" href="css/main.css">
	<link rel="stylesheet" href="css/comparison.css">
	<script src="js/vendor/modernizr-2.6.1.min.js"></script>
	<script src="js/comparison.js"></script>
</head>
<body onload="javascript:loadSelected();">
<h1>#{@gen.global_name}</h1>
<div class="comparison-header">
	<ul>
__EOF__
		@gen.topics.each_with_index { |t, i|
			@out.puts "\t\t<li><input id=\"check-#{t}\" type=\"checkbox\" checked=\"1\" onclick=\"javascript:switchColumn(this, #{i + 1});\"/> #{@gen.topic_names[t]}</li>"
		}
		@out.puts <<__EOF__
	</ul>
</div>
<table class="comparison" id="comparison">
<tr class="topic-header">
	<th/>
__EOF__
		@gen.topics.each { |t|
			@out.puts "\t<th id=\"column-#{t}\">#{@gen.topic_names[t]}</th>"
		}
		@out.puts '</tr>'
	end

	def global_footer
		@out.puts <<__EOF__
</table>
</body>
</html>
__EOF__
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
