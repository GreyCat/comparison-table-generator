# -*- coding: utf-8 -*-

require 'erb'

class HTMLGenerator
	def initialize(opt, tmpl_file, out_file)
		@tmpl = File.open(File.join(opt[:style], tmpl_file)).read
		@out_path = File.join(opt[:out], out_file)
	end

	def run(data)
		# TODO: mkdir all components of path
		File.open(@out_path, 'w') { |f|
			f << ERB.new(@tmpl).result(data)
		}
	end
end
