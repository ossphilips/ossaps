Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |file| require file }
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :aps do
  desc "Starts the PreProcessing script"
  task :process do 

    input_dir = (input_dir = ENV['INPUT_DIR']) && Pathname.new(input_dir)
    output_dir = (output_dir = ENV['OUTPUT_DIR']) && Pathname.new(output_dir)

    begin
      s = Time.now
      puts "[%s]: Start preprocessing" % s
      BatchList.new(input_dir, output_dir).process
      e = Time.now
      puts "[%s]: Preprocessing finished (%.2fs)" % [e, (e - s)]
    rescue => e
      msg = []
      msg << "[ERROR]: #{e.message}"
      msg << 'Usage: rake aps:process INPUT_DIR=/path/to/input_dir OUTPUT_DIR=/path/to/output'
      $stderr.puts msg
      exit 1
    end
  end
end
