require 'factory_girl'
require 'vcr'

FactoryGirl.find_definitions

VCR.configure do |config|
  config.cassette_library_dir     = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  #config.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  config.filter_run :focus => true
  config.alias_example_to :fit, :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  config.add_setting :output_root
  config.output_root = Pathname.new('tmp/test')

  config.after(:each) {
    config.output_root.rmtree if config.output_root.exist?
  }
end
