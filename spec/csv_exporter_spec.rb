require 'spec_helper'
require 'csv_exporter'
require 'luminaire'
require 'aps_logger'
require 'nokogiri'
require 'open-uri'

describe CsvExporter do
  let(:output_root) { Pathname.new(RSpec.configuration.output_root) }
  let(:output_dir) { output_root.join('output') }
  let(:lum1) { FactoryGirl.build(:luminaire) }
  let(:lum2) { FactoryGirl.build(:luminaire) }
  let(:luminaires) { [lum1, lum2] }

  HEADER = ["CTN", "Fam name", "Item nbr", "Has Colorsheet", "Has 3DView", "Complete?"]

  describe '::HEADER' do
    subject{ described_class::HEADER }
    it{ should eql HEADER }
  end

  describe '.to_row' do
    luminaire = FactoryGirl.build(:luminaire)
    let(:expected_values){ [luminaire.ctn, luminaire.ctn[0..4], luminaire.itemnr, luminaire.has_colorsheet?.to_s, luminaire.has_view3d?.to_s, luminaire.is_complete?.to_s] }
    subject { described_class.to_row luminaire }
    before do
      luminaire.stub(:has_colorsheet?).and_return("colorsheet")
      luminaire.stub(:has_view3d?).and_return("view3d")
      luminaire.stub(:is_complete?).and_return("complete")
    end
    its(:size){ should eql described_class::HEADER.size}
    it{ should eql expected_values}
  end

  describe '.export_all' do
    let(:output_file) { output_dir.join('export.csv') }
    let(:contents) { File.read(output_file) }
    before do
      output_dir.mkpath
    end
    subject{ described_class.export_all(luminaires, output_file) }
    context 'no output_path' do
      let(:output_file) { nil }
      it 'raises and error when outputpath is missing' do
        ApsLogger.should_receive(:log).with(:fatal, "Outputpath missing for creating CVS file").and_raise("Error")
        expect{ subject }.to raise_error
      end
    end
    context 'valid outputpath' do
      it 'creates a csv file' do
        output_file.should_not exist
        subject
        output_file.should exist
      end
      it 'should contain the header row' do
        subject
        contents.should include(HEADER.join(','))
      end
      it 'should contain the luminaires' do
        subject
        file = File.open(output_file)
        file.readlines.size.should eql 3
      end
    end
  end
end
