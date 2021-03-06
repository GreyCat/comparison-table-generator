# -*- coding: utf-8 -*-
require 'fileutils'
require_relative 'statistics'
require_relative 'htmlhelper'

class Generator
	include HTMLHelper

	attr_reader :topics
	attr_reader :topic_names
	attr_reader :global_name

	MACRO_DIR = '_macro'

	def initialize(opt)
		@opt = opt

		@topics = []
		@topic_names = {}
		@stat = Statistics.new

		@lang = @opt[:lang] || DEFAULT_LANG
		@opt[:topics] = find_file('', 'topics') unless @opt[:topics]

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

		@macros = {
			'plain' => ERB.new('<a href="<%= r[:url] %>"><%= r[:url] %></a>', nil, nil, "_ePLAIN")
		}

		# Load style builtin macros
		load_macros(File.join(@opt[:style], MACRO_DIR)) if Dir.exists?(File.join(@opt[:style], MACRO_DIR))

		# Load topic-specific macros
		load_macros(File.join(@opt[:dir], MACRO_DIR)) if Dir.exists?(File.join(@opt[:dir], MACRO_DIR))
	end

	def run
		Dir.mkdir(@opt[:out])
		['css', 'js'].each { |dir|
			FileUtils.cp_r(File.join(@opt[:style], dir), @opt[:out])
		}

		render_and_output('table_header.rhtml', binding, 'full.html')
		recurse_dir(1, '')
		render_and_append('table_footer.rhtml', binding, 'full.html')

		@stat.report
	end

	def recurse_dir(depth, dir)
		Dir.entries(File.join(@opt[:dir], dir)).sort.each { |d|
			next if d.start_with?('.') or d.start_with?('_') or d.end_with?('~')
			path = File.join(dir, d)
			check_validity(path) unless depth == 1
			next unless FileTest.directory?(File.join(@opt[:dir], path))

			index_html = File.join(output_path(path.split('/').slice(0, MAX_DETAIL_DEPTH + 1).join('/')), 'index.html')
			render_and_append('table_header.rhtml', binding, index_html) if depth <= MAX_DETAIL_DEPTH
			process_dir(depth, path)
			recurse_dir(depth + 1, path)
			render_and_append('table_footer.rhtml', binding, index_html) if depth <= MAX_DETAIL_DEPTH
		}
	end

	MAX_DETAIL_DEPTH = 2

	def process_dir(depth, dir)
		index_html = File.join(output_path(dir.split('/').slice(0, MAX_DETAIL_DEPTH + 1).join('/')), 'index.html')

		desc = read_file(dir, 'desc')
		desc_long = read_file(dir, 'desc-long')
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
				c = process_cell(dir, t, data[t])
				render_and_output('cell.rhtml', binding, c[:link])
				cols << c
			}
			render_and_append('row.rhtml', binding, 'full.html')
			render_and_append('row.rhtml', binding, index_html)
		end
	end

	# Process one cell and prepare cell structure.
	#
	# @param dir [String] directory path to process
	# @param t [String] topic to process; will be used to search for additional files
	# @param data [String] pre-read contents of the main data file for the given topic
	# @return cell structure
	def process_cell(dir, t, data)
		c = { :data => data }

		c[:long] = read_file(dir, "#{t}-long")

		fn = find_file(dir, "#{t}-ref")
		c[:refs] = File.open(fn).readlines.map { |x| parse_macro(x.chomp) } if fn

		@stat.inc!(t, :total)
		@stat.inc!(t, :empty) if c[:data].nil?
		@stat.inc!(t, :no_ref) if c[:refs].nil? and c[:data]

		# Parse special tags that influence cell
		# styles: must be come first
		case c[:data]
		when /^<(yes|no|na)\s*\/?>(.*)$/mi
			c[:symbol] = $1
			c[:data] = $2
		end

		# Prepare bare, linkless version for row template
		c[:data_bare] = c[:data].gsub(/<a href="(.*?)">(.*?)<\/a>/, '\2') if c[:data]

		# Render macros in refs
		c[:refs].map! { |r|
			macro = @macros[r[:macro]]
			raise ParseException.new("Unknown macro found: \"#{r[:macro]}\"") unless macro
			macro.result(binding)
		} if c[:refs]

		# Strip ordering numbers from the beginning of directories' names
		cell_dir = output_path(dir)
		c[:link] = "#{cell_dir}/#{t}.html"

		c
	end

	class ParseException < Exception; end

	KINDS = [
		'ref',
		'long',
	]

	# Checks that directory entry is valid and we know how to
	# interprete it. If we don't, raises a parsing exception.
	def check_validity(f)
		fn = File.join(@opt[:dir], f)

		# Any directory is valid - we'll just recurse into it.
		# We're only checking file names.
		return if FileTest.directory?(fn)

		n = File.basename(f)

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
			f = File.join(@opt[:dir], dir, x)
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

	# Returns output path for a give source directory: strips
	# heading '/' from source directory, strips ordering numbers (i.e.
	# "10-abc" => "abc")
	def output_path(dir)
		return '' if dir.nil? or dir.empty?
		dir[1..-1].split('/').map { |x| x.gsub(/^\d\d-/, '') }.join('/')
	end

	def load_macros(dir)
		Dir.entries(dir).each { |f|
			macro_file = File.join(dir, f)
			next if f.start_with?('.')
			macro_cnt = File.read(macro_file)
			@macros[f] = ERB.new(macro_cnt, nil, nil, "_e#{f.hash.abs}")
			$stderr.puts "Loaded macro: #{f}"
		}
	end

	def parse_macro(str)
		unless str =~ /^\{\{(.*)\}\}$/
			return :macro => 'plain', :url => str
		else
			name, *args = $1.split('|')
			res = { :macro => name }
			argnum = 0
			args.each { |a|
				if a =~ /^(.*)=(.*)$/
					res[$1] = $2
				else
					res[argnum] = a
					argnum += 1
				end
			}
			return res
		end
	end
end
