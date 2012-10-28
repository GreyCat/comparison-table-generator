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
end
