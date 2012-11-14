require 'erb'
require 'fileutils'
require 'cgi'

module HTMLHelper
	@@tmpl_cache = {}

	def render_and_output(tmpl_file, data, out_file)
		render_to_stream(tmpl_file, data, out_file, 'w')
	end

	def render_and_append(tmpl_file, data, out_file)
		render_to_stream(tmpl_file, data, out_file, 'a')
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

	def htmlize(str)
		CGI.escapeHTML(str)
	end

	private
	def out_path(out_file)
		File.join(@opt[:out], out_file)
	end

	def render_to_stream(tmpl_file, data, out_file, stream_mode)
		path = out_path(out_file)

		@nav_path = out_file.split('/')
		updir_cnt = @nav_path.length - 1
		updir_cnt = 0 if updir_cnt < 0
		@root_path = '../' * updir_cnt

		FileUtils.mkdir_p(File.dirname(path))
		File.open(path, stream_mode) { |f|
			f << render(tmpl_file, data)
		}
	end
end
