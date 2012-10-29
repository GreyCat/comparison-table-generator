class Statistics
	class Counter
		def initialize
			@data = {}
		end

		def inc!(which)
			v = @data[which] || 0
			@data[which] = v + 1
		end

		def to_s
			sprintf(
				'%d (%d%% empty, %d%% w/o ref)',
				@data[:total],
				@data[:empty] * 100.0 / @data[:total],
				@data[:no_ref] * 100.0 / @data[:total]
			)
		end
	end

	def initialize
		@cnt = {}
	end

	def inc!(topic, which)
		@cnt[topic] = Counter.new unless @cnt[topic]
		@cnt[topic].inc!(which)
	end

	def report
		puts "Statistics:"
		@cnt.keys.sort.each { |k|
			printf "%25s: %s\n", k, @cnt[k]
		}
	end
end