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
  let(:luminaires_dir){ output_dir.join('luminaires') }
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

    #TODO fix test to check exception
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
      it 'writes files into the luminaires directory' do
        luminaires_dir.join('16254', test_file).should exist
      end

      it 'writes a CSV file to the output directory' do
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
        SummaryExporter.should_receive(:export_all).ordered
        CsvExporter.should_receive(:export_all).ordered
      end
      it 'check' do
        subject
      end
    end
  end

  describe '.download_reference_images', vcr: vcr_options do
    let(:ctn){ '162548716' }
    let(:luminaire) { FactoryGirl.build(:luminaire, ctn: ctn) }
    let(:luminaires ){ [ luminaire ] }
    let(:download_dir){ luminaires_dir.join(luminaire.fam_name, luminaire.ctn) }
    subject { described_class.download_reference_images luminaires, luminaires_dir }

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
    let(:expected_colorsheet) { [ luminaires_dir.join('16254', '16254-COLORSHEET.XLS'), nil, nil] }
    let(:expected_colorsheet_mtime) { [Time.new(2011,10,14,6,42,32,'+02:00'), nil, nil] }
    let(:expected_3dview) { [luminaires_dir.join('16254', '16254-3DVIEW.JT'), luminaires_dir.join('16321','16321-3DVIEW.JT'), nil] }
    let(:expected_3dview_mtime) { [Time.new(2012,07,26,15,48,32,'+02:00'), Time.new(2011,06,27,14,40,14,'+02:00'), nil] }
    let(:expected_reference_images) { [
      ['ref.jpg', 'ref.JPG', 'ref.bmp', 'ref.tif', 'ref.gif', 'ref.pdf'].map { |img| luminaires_dir.join('16254','162548716', img) },
      [],
      []
    ] }

    before do
      ApsLogger.should_receive(:log).at_least(:once)
      described_class.enrich_luminaires zip_file, lums, luminaires_dir
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

    it 'copies all reference images' do
      lums.each_with_index do |lum, i|
        lum.reference_images.map {|img| img[:file]}.should =~ expected_reference_images[i]
        lum.reference_images.each do |img|
          img[:type].should eq :ref
          img[:file].should exist
        end
      end
    end

    it 'preserves the timestamp of the reference images' do
      jpg_img = lums[0].reference_images.select {|img|img[:file].to_s.end_with? 'jpg'}[0][:file]
      jpg_img.mtime.should eq Time.new(2014,5,8,14,33,49,"+02:00")
    end

  end

  describe '.path2ctn' do
    it 'retrieves the ctn from the path' do
      expect(BatchList.path2ctn('DOCUMENTS/162548716-915004122901/915004122901-DEVELOPMNT-3DVIEW.088505.JT')).to eql('162548716')
    end

    it 'retrieves the ctn from the path also when no gtin in the path' do
      expect(BatchList.path2ctn('DOCUMENTS/163219316withoutgtinpostfix/915002532202-DEVELOPMNT-3DVIEW.078658.JT')).to eql('163219316')
    end

    it 'retrieves the ctn from the path also when ctn contains alphanumeric main color' do
      expect(BatchList.path2ctn('DOCUMENTS/16254IN16-915004122901/915004122901-DEVELOPMNT-3DVIEW.088505.JT')).to eql('16254IN16')
    end
  end

  describe '.path2ctn' do
    fit 'returns true only for supported image types' do
      %W(Jpg tiF BMP gif pdf).each do |ext|
        expect(BatchList.is_a_photo('foo/a.' + ext)).to be_true
      end
    end

  end
end
