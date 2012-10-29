# -*- coding: utf-8 -*-
require_relative 'statistics'
require_relative 'htmltablegenerator'

class Generator
	attr_reader :topics
	attr_reader :topic_names
	attr_reader :global_name

	def initialize(opt)
		@opt = opt

		@topics = []
		@topic_names = {}
		@stat = Statistics.new

		@lang = @opt[:lang] || DEFAULT_LANG
		@opt[:topics] = "#{@opt[:dir]}/topics-#{@lang}" unless @opt[:topics]

		File.open(@opt[:topics], 'r') { |f|
			f.each_line { |l|
				l.chomp!
				topic, name = l.split(/\t/)
				@topics << topic
				@topic_names[topic] = name
			}
		}

		@global_name = File.open("#{@opt[:dir]}/desc-#{@lang}").read.chomp
	end

	def run
		Dir.mkdir(@opt[:out])
		['css', 'js'].each { |dir|
			FileUtils.cp_r(File.join(@opt[:style], dir), @opt[:out])
		}

		@full_page = HTMLTableGenerator.new(
			self,
			File.open(File.join(@opt[:out], 'full.html'), 'w')
		)

		@full_page.global_header
		recurse_dir(1, @opt[:dir])
		@full_page.global_footer

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
		desc = File.open("#{dir}/desc-#{@lang}").read.chomp
		only_header = true
		data = {}
		@topics.each { |t|
			fn = "#{dir}/#{t}"
			if FileTest.readable?(fn)
				data[t] = File.open(fn).read.chomp
				only_header = false
			end
		}

		if only_header
			@full_page.row_header(depth, desc)
		else
			cols = []
			@topics.each { |t|
				c = { :data => data[t] }

				fn = "#{dir}/#{t}-ref"
				c[:refs] = File.open(fn).readlines if FileTest.readable?(fn)

				@stat.inc!(t, :total)
				@stat.inc!(t, :empty) if c[:data].nil?
				@stat.inc!(t, :no_ref) if c[:refs].nil?

				cols << c
			}
			@full_page.row(desc, cols)
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
end
