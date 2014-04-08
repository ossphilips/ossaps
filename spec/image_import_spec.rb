require 'spec_helper'
require_relative '../lib/image_import'
require_relative '../lib/luminaire'

describe ImageImport do
  let(:ctn){ '162548716' }
  let(:output_root) { RSpec.configuration.output_root }
  let(:output_dir) { output_root.join('output') }
  let(:types){ ['DPP', 'RTP', 'APP', 'A1P', 'UPL'] }

  vcr_options = {:cassette_name => 'images.philips.com', :record => :new_episodes}


  shared_examples 'a downloaded image array' do |expected_types|
      it 'has the expected image types' do
        subject.map { |img| img[:type] }.should == expected_types
      end

      it 'has the correct url and file for each image' do
        subject.each do |img|
          img[:file].should eql output_dir.join("#{ctn}-#{img[:type]}.jpg")
          img[:file].should exist
        end
      end
  end

  describe '.download_reference_images', vcr: vcr_options do
    let(:ctn) { '162548716' }

    subject { described_class.download_reference_images ctn, output_dir }

    context 'portrait image' do
      let(:ctn){ '162548716' }
      it_should_behave_like 'a downloaded image array', [:RTP, :APP]
    end

    context 'landscape url' do
      let(:ctn){ '455739316' }
      it_should_behave_like 'a downloaded image array', [:RTP, :APP, :A1P]
    end

    context 'invalid ctn' do
      let(:ctn){ 'invalid' }
      it{ should be_empty }
    end
  end

  describe '.image_path' do
    [:DPP,:RTP,:APP,:A1P,:UPL].each do |type|
      context "type #{type}" do
        subject{ described_class.image_path ctn, type, 'wid=1200' }
        it { should eql "/is/image/PhilipsConsumer/#{ctn}-#{type}-global-001?wid=1200&op_sharpen=1&qlt=95" }
      end
    end
  end

end
