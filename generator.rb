# -*- coding: utf-8 -*-
require_relative 'statistics'
require_relative 'htmlhelper'

$tmpcnt = 0

class Generator
	include HTMLHelper

	attr_reader :topics
	attr_reader :topic_names
	attr_reader :global_name

	def initialize(opt)
		@opt = opt

		@topics = []
		@topic_names = {}
		@stat = Statistics.new

		@lang = @opt[:lang] || DEFAULT_LANG
		@opt[:topics] = find_file(@opt[:dir], 'topics') unless @opt[:topics]

		raise ParseException.new('Main topic file not found') unless @opt[:topics]

		File.open(@opt[:topics], 'r') { |f|
			f.each_line { |l|
				l.chomp!
				topic, name = l.split(/\t/)
				@topics << topic
				@topic_names[topic] = name
			}
		}

		@global_name = read_file(@opt[:dir], 'desc')
	end

	def run
		Dir.mkdir(@opt[:out])
		['css', 'js'].each { |dir|
			FileUtils.cp_r(File.join(@opt[:style], dir), @opt[:out])
		}

		render_and_output('table_header.rhtml', binding, 'full.html')
		recurse_dir(1, @opt[:dir])
		render_and_append('table_footer.rhtml', binding, 'full.html')

		@stat.report
	end

	def recurse_dir(depth, dir)
		Dir.glob("#{dir}/*").sort.each { |d|
			check_validity(d) unless depth == 1
			next unless FileTest.directory?(d)
			process_dir(depth, d)
			recurse_dir(depth + 1, d)
		}
	end

	def process_dir(depth, dir)
		desc = read_file(dir, 'desc')
		only_header = true
		data = {}
		@topics.each { |t|
			data[t] = read_file(dir, t)
			only_header = false if data[t]
		}

		if only_header
			render_and_append('row_header.rhtml', binding, 'full.html')
		else
			cols = []
			@topics.each { |t|
				c = { :data => data[t] }

				fn = find_file(dir, "#{t}-ref")
				c[:refs] = File.open(fn).readlines.each { |x| x.chomp! } if fn

				@stat.inc!(t, :total)
				@stat.inc!(t, :empty) if c[:data].nil?
				@stat.inc!(t, :no_ref) if c[:refs].nil?

				# Parse special tags that influence cell
				# styles: must be come first
				case c[:data]
				when /^<(yes|no|na)\s*\/?>(.*)$/mi
					c[:symbol] = $1
					c[:data] = $2
				end

				c[:link] = "#{$tmpcnt}.html"

				render_and_output('cell.rhtml', binding, c[:link])

				$tmpcnt += 1

				cols << c
			}
			render_and_append('row.rhtml', binding, 'full.html')
		end
	end

	class ParseException < Exception; end

	KINDS = [
		'ref',
		'long',
	]

	# Checks that directory entry is valid and we know how to
	# interprete it. If we don't, raises a parsing exception.
	def check_validity(fn)
		# Any directory is valid - we'll just recurse into it.
		# We're only checking file names.
		return if FileTest.directory?(fn)

		n = File.basename(fn)

		topic = kind = lang = nil

		case n
		when /^([^-]+)$/
			topic = $1
		when /^([^-]+)-([^-]+)$/
			topic = $1
			if KINDS.include?($2)
				kind = $2
			else
				lang = $2
			end
		when /^([^-]+)-([^-]+)-([^-]+)$/
			topic, kind, lang = $1, $2, $3
		end

		# Just a topic name: normal table data entry, good
		# for all languages
		raise ParseException.new("Unknown topic '#{topic}' encountered in file '#{fn}'") unless @topic_names[topic] or topic == 'desc'

		# Language must be 2-letter code, if present
		raise ParseException.new("Bad language code '#{lang}' encountered in file '#{fn}'") unless lang.nil? or lang =~ /^[a-z]{2}$/

		# Kind must be a valid kind
		raise ParseException.new("Invalid kind of file '#{kind}' encountered in file '#{fn}'") unless kind.nil? or KINDS.include?(kind)
	end

	# Propagation method for ERB templates to access generator fields
	def get_binding
		binding
	end

	# Tries to find a file and returns full path to the file found:
	# first tries a file in preferred language, then tries a generic
	# file without a language, and, if all fails, returns nil.
	def find_file(dir, fn)
		["#{fn}-#{@lang}", fn].each { |x|
			f = File.join(dir, x)
			return f if FileTest.readable?(f)
		}
		return nil
	end

	# Reads a file, trying various localized versions, as specified
	# in find_file(dir, fn). Returns file as a chomped string, if
	# found. Returns nil, if file is missing.
	def read_file(dir, fn)
		fp = find_file(dir, fn)
		fp ? File.read(fp).chomp : nil
	end
end
