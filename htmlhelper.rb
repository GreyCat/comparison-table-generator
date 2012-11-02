require 'erb'

module HTMLHelper
	def render_and_output(tmpl_file, data, out_file)
		# TODO: mkdir all components of path
		File.open(out_path(out_file), 'w') { |f|
			f << render(tmpl_file, data)
		}
	end

	def render_and_append(tmpl_file, data, out_file)
		# TODO: mkdir all components of path
		File.open(out_path(out_file), 'a') { |f|
			f << render(tmpl_file, data)
		}
	end

	def render(tmpl_file, data)
		tmpl = File.open(File.join(@opt[:style], tmpl_file)).read
		ERB.new(tmpl, nil, nil, "_e#{tmpl_file.hash.abs}").result(data)
	end

	private
	def out_path(out_file)
		File.join(@opt[:out], out_file)
	end
end
