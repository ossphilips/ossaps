require 'spec_helper'
require 'aps_logger'

describe ApsLogger do
  let(:output_root) { Pathname.new(RSpec.configuration.output_root) }
  let(:output_dir) { output_root.join('output') }
  let(:log_file) { File.join(output_dir,"log.txt") }
  subject { described_class }

  before do
    FileUtils.mkdir_p output_dir
  end

  describe '.log' do
    let(:message) { "An Error Message" }
    let(:level) { :info }
    subject { described_class.log level, message }
    context 'not initialized before use' do
      it 'raises error' do
        expect{ subject }.to raise_error
      end
    end

    context 'initialize twice' do
      before do
        described_class.new log_file
        described_class.log :error, 'message 1'
        described_class.new log_file
        described_class.log :error, 'message 2'
      end
      let(:content){ File.open(log_file).read }
      it 'append to the log' do
        content.should include 'message 1'
        content.should include 'message 2'
      end
    end

    context 'initialized before use' do
      before do
        described_class.new log_file
      end
      context 'non-verbose' do
        context 'info' do
          it 'log should not write to STDOUT' do
            STDOUT.should_not_receive(:puts)
            subject
          end
          it 'does not log info messages' do
            Logger.any_instance.should_not_receive(:info)
            subject
          end
        end

        context 'warn' do
          let(:level){ :warn }
          it 'log should not write to STDOUT' do
            STDOUT.should_not_receive(:puts)
            subject
          end
          it 'call the logger with correct params' do
            Logger.any_instance.should_receive(:warn).with(message)
            subject
          end
          it 'does not raise error' do
            expect{ subject}.to_not raise_error
          end
        end

        context 'error' do
          let(:level){ :error }
          it 'log should not write to STDOUT' do
            STDOUT.should_not_receive(:puts)
            subject
          end
          it 'call the logger with correct params' do
            Logger.any_instance.should_receive(:error).with(message)
            subject
          end

          it 'does not raise error' do
            expect{ subject}.to_not raise_error
          end
        end
        context 'fatal' do
          let(:level){ :fatal }
          it 'log should write to STDOUT' do
            Logger.any_instance.should_receive(:fatal).with(message)
            STDOUT.should_receive(:puts)
            expect{ subject}.to raise_error
          end
        end
      end
      context 'verbose' do
        before do
          ENV['VERBOSE'] = 'true'
        end
        after do
          ENV['VERBOSE'] = nil
        end
        it 'log should write to STDOUT and log info messages' do
          STDOUT.should_receive(:puts)
          Logger.any_instance.should_receive(:info).with(message)
          subject
        end
      end
    end
  end
end

