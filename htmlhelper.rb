require 'erb'

module HTMLHelper
	def render_and_output(tmpl_file, data, out_file)
		out_path = File.join(@opt[:out], out_file)

		# TODO: mkdir all components of path
		File.open(out_path, 'w') { |f|
			f << render(tmpl_file, data)
		}
	end

	def render(tmpl_file, data)
		tmpl = File.open(File.join(@opt[:style], tmpl_file)).read
		ERB.new(tmpl, nil, nil, "_e#{tmpl_file.hash.abs}").result(data)
	end
end
