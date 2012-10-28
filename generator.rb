class Generator
	attr_reader :topics
	attr_reader :topic_names
	attr_reader :global_name

	def initialize(opt)
		@opt = opt

		@topics = []
		@topic_names = {}
		@stat = { '_total' => Counters.new }

		@lang = @opt[:lang] || DEFAULT_LANG
		@opt[:topics] = "#{@opt[:dir]}/topics-#{@lang}" unless @opt[:topics]

		File.open(@opt[:topics], 'r') { |f|
			f.each_line { |l|
				l.chomp!
				topic, name = l.split(/\t/)
				@topics << topic
				@topic_names[topic] = name
				@stat[topic] = Counters.new
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

		report_stat
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
				@stat['_total'].total += 1
				@stat[t].total += 1

				if c[:data].nil?
					@stat['_total'].empty += 1
					@stat[t].empty += 1
				end

				fn = "#{dir}/#{t}-ref"
				c[:refs] = File.open(fn).readlines if FileTest.readable?(fn)
				if c[:refs].nil?
					@stat['_total'].no_ref += 1
					@stat[t].no_ref += 1
				end

				cols << c
			}
			@full_page.row(desc, cols)
		end
	end

	def report_stat
		puts "Statistics:"
		@stat.keys.sort.each { |k|
			printf "%25s: %s\n", k, @stat[k]
		}
	end
end
