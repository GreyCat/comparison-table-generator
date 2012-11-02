require 'erb'

module HTMLHelper
	@@tmpl_cache = {}

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
		tmpl = @@tmpl_cache[tmpl_file]
		unless tmpl
			tmpl_path = File.open(File.join(@opt[:style], tmpl_file)).read
			tmpl = ERB.new(tmpl_path, nil, nil, "_e#{tmpl_file.hash.abs}")
			@@tmpl_cache[tmpl_file] = tmpl
		end
		return tmpl.result(data)
	end

	private
	def out_path(out_file)
		File.join(@opt[:out], out_file)
	end
end
