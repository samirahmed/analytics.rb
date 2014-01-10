$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark'
require 'analytics'
require 'thwait'

raise "No Analytics Key Provided" unless ENV['GA_TRACKING_ID'] 

# configure analytics
Analytics.configure ENV['GA_TRACKING_ID'], "BenchmarkTest"

reps = [1, 10, 100, 1000]

Benchmark.bm do |bm|

  puts "Main Thread Time"

  reps.each do |count|
    threads = []
    bm.report("#{count}x\t:") do
      count.times{ threads << Analytics.event( category: "benchmarking", label: "event logging - main thread")}
    end
    ThreadsWait.all_waits(*threads)
    sleep 5
  end

  puts "Total Time"

  reps.each do |count|
    bm.report("#{count}x\t:") do
      threads = []
      count.times{ threads << Analytics.event( category: "benchmarking", label: "event logging - all threads" )}
      ThreadsWait.all_waits(*threads)
    end
    sleep 5
  end
end
