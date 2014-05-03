require 'spec_helper'
require 'batch_list'
require 'color_sheet'
require 'view3d'
require 'summary_exporter'

describe BatchList do

  vcr_options = {:cassette_name => 'images.philips.com', :record => :new_episodes}

  let(:output_root) { RSpec.configuration.output_root }
  let(:output_dir) { output_root.join('output') }
  let(:fixtures){ Pathname.new('spec/fixtures') }
  let(:incomplete_dir){ output_dir.join('incomplete') }
  let(:complete_dir){ output_dir.join('complete') }
  let(:working_dir){ output_dir.join('working') }
  let(:input_dir){ fixtures.join('input_dir') }
  let(:batch_list) { described_class.new input_dir, output_dir}
  let(:zip_file) { fixtures.join('input_dir', 'hld_batch_small_XX.zip') }
  before do
    output_dir.mkpath
  end

  describe '#initialize' do
    subject{ batch_list}
    before do
      #Suppress standard out to prevent fatal messages to be printed during testing
      $stdout = StringIO.new
    end

    after do
      $stdout = STDOUT
    end
    context 'valid input_dir' do
      it 'should instantiate a Logger object' do
        subject.instance_variable_get(:@logger).should be_a_kind_of ApsLogger
      end
    end
    context 'Too many files' do
      let(:input_dir){ output_root.join('input') }
      before do
        input_dir.mkpath
      end

      context 'multiple Excel files in input_dir' do
        before do
          FileUtils.touch File.join(input_dir,'test.zip')
          FileUtils.touch File.join(input_dir,'test1.xls')
          FileUtils.touch File.join(input_dir,'test2.xls')
        end
        it 'raises error' do
          expect{ subject }.to raise_error "Found more then one Excel file in directory #{input_dir}"
        end
      end
      context 'multiple zipfiles in input_dir' do
        before do
          FileUtils.touch File.join(input_dir,'test.xls')
          FileUtils.touch File.join(input_dir,'test1.zip')
          FileUtils.touch File.join(input_dir,'test2.zip')
        end
        it 'raises error' do
          expect{ subject }.to raise_error "Found more then one Zipfile in directory #{input_dir}"
        end
      end

    end
    context 'missing files' do
      let(:input_dir){ output_root.join('input') }
      before do
        input_dir.mkpath
      end
      context 'zipfile missing in input_dir' do
        before do
          FileUtils.touch File.join(input_dir,'test.xls')
        end
        it 'raises error' do
          expect{ subject }.to raise_error "Zipfile missing in directory #{input_dir}"
        end
      end
      context 'xls missing in input_dir' do
        before do
          FileUtils.touch File.join(input_dir,'test.zip')
        end
        it 'raises error' do
          expect{ subject }.to raise_error "Excel file missing in directory #{input_dir}"
        end
      end
    end
  end

  describe '.process', :vcr => vcr_options do
    let(:test_file) { "16254-COLORSHEET.XLS" }
    subject{ batch_list.process }

    context 'Exception raised' do
      let(:file_name) { test_file }
      before do
        subject
      end
      it 'writes exception in logfile' do
        output_dir.join('error_log.txt').should exist
      end
    end

    context 'when files are present' do
      before do
        subject
      end
      it 'should check if test file is present' do
        output_dir.join('complete', '16254', test_file).should exist
      end

      it 'should check if there is a present CSV file' do
        output_dir.join("luminaires.csv").should exist
      end
    end

    describe 'calls class methods in right order' do
      let(:ctn){ '162548716' }
      let(:luminaire) { FactoryGirl.build(:luminaire, ctn: '162548716') }
      let(:luminaires_hash ){ { ctn: luminaire } }
      let(:exporter){ double('Exporter') }
      before do
        described_class.should_receive(:enrich_luminaires).ordered
        described_class.should_receive(:download_reference_images).ordered
        described_class.should_receive(:move_to_targetdir).ordered
        SummaryExporter.should_receive(:export_all).ordered
        CsvExporter.should_receive(:export_all).ordered
      end
      it 'check' do
        subject
      end
    end
  end



  describe '.move_to_targetdir' do
    let(:lums) { [
      FactoryGirl.build(:luminaire, ctn: '162548716'),
      FactoryGirl.build(:luminaire, ctn: '163219316')
    ] }
    let(:files) { ['foo.XlSx', 'bar.jt'] }
    subject{ described_class.move_to_targetdir lums, working_dir, output_dir}
    before do
      lums[0].stub(:is_complete?).and_return(true)
      lums[1].stub(:is_complete?).and_return(false)
      lums.each do |lum|
        fam_dir = working_dir.join(lum.fam_name)
        fam_dir.join(lum.ctn).mkpath
        FileUtils.touch files.map {|f| fam_dir.join(f) }
      end
    end

    it 'copies all family files for all luminaires and preserves modification time' do
      mtimes = {}
      lums.each do |lum|
        files.each {|f| mtimes[[lum, f]] = working_dir.join(lum.fam_name, f).mtime }
      end
      subject
      lums.each do |lum|
        dir = output_dir.join(lum.is_complete? ? 'complete' : 'incomplete', lum.fam_name)
        dir.should exist
        files.each {|f| dir.join(f).mtime.should eq mtimes[[lum, f]]}
      end
    end

    it 'handles existing complete folder' do
      output_dir.join("complete").mkpath
      expect { subject }.not_to raise_error
    end
  end

  describe '.download_reference_images', vcr: vcr_options do
    let(:ctn){ '162548716' }
    let(:luminaire) { FactoryGirl.build(:luminaire, ctn: ctn) }
    let(:luminaires ){ [ luminaire ] }
    let(:download_dir){ working_dir.join(luminaire.fam_name, luminaire.ctn) }
    subject { described_class.download_reference_images luminaires, working_dir }

    it 'enriches all luminaires with downloaded reference images' do
      subject
      luminaires.each do |luminaire|
        luminaire.should have_reference_images
      end
    end

    it 'should download reference images' do
      subject
      ['RTP', 'APP'].each do |type|
        expected_file = download_dir.join("#{ctn}-#{type}.jpg")
        expected_file.should exist, "Missing reference image, expected #{expected_file}"
      end
    end
  end

  describe '.enrich_luminaires' do
    let(:lums) { Luminaires.new <<
      FactoryGirl.build(:luminaire, ctn: '162548716') <<
      FactoryGirl.build(:luminaire, ctn: '163219316') <<
      FactoryGirl.build(:luminaire, ctn: '016520616')
    }
    let(:expected_colorsheet) { [ working_dir.join('16254', '16254-COLORSHEET.XLS'), nil, nil] }
    let(:expected_colorsheet_mtime) { [ Time.new(2011,10,14,6,42,32,'+02:00'), nil, nil] }
    let(:expected_3dview) { [working_dir.join('16254', '16254-3DVIEW.JT'), working_dir.join('16321','16321-3DVIEW.JT'), nil] }
    let(:expected_3dview_mtime) { [ Time.new(2012,07,26,15,48,32,'+02:00'), Time.new(2011,06,27,14,40,14,'+02:00'), nil] }
    let(:expected_reference_images) { [
      ['ref1.jpg', 'ref2.jpg'].map { |img| working_dir.join('16254','162548716', img) },
      ['ref1.jpg', 'ref2.jpg'].map { |img| working_dir.join('16321','163219316', img) },
      nil
    ] }
    let(:expected_reference_images_mtime) { [
      [ Time.new(2014,02,10,10,53,00,'+01:00'), Time.new(2014,02,10,11,00,39,'+01:00')],
      [ Time.new(2014,02,10,10,53,00,'+01:00'), Time.new(2014,02,10,11,00,39,'+01:00')],
      nil
    ] }

    before do
      ApsLogger.should_receive(:log).at_least(:once)
      described_class.enrich_luminaires zip_file, lums, working_dir
    end

    it 'copies the colorsheets only if present preserving the timestamp' do
      lums.each_with_index do |lum, i|
        if expected_colorsheet[i]
           lum.colorsheet.should be_a_kind_of ColorSheet
           expected_colorsheet[i].mtime.should eq expected_colorsheet_mtime[i]
        else
           lum.colorsheet.should be_nil
        end
      end
    end

    it 'copies the 3dview only if present preserving the timestamp' do
      lums.each_with_index do |lum, i|
        if expected_3dview[i]
           lum.view3d.should be_a_kind_of View3D
           expected_3dview[i].mtime.should eq expected_3dview_mtime[i]
        else
           lum.view3d.should be_nil
        end
      end
    end

   it 'copies the reference images only if present preserving the timestamp' do
      lums.each_with_index do |lum, i|
        if expected_reference_images[i]
           lum.reference_images.should_not be_empty
           expected_reference_images[i].each_with_index do |img, j|
             img.mtime.should eq expected_reference_images_mtime[i][j]
           end
        else
           lum.reference_images.should be_empty
        end
      end
    end

  end
end
