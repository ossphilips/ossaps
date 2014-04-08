require 'spec_helper'
require 'summary_exporter'
require 'luminaire'

describe SummaryExporter do
  let(:output_root) { Pathname.new(RSpec.configuration.output_root) }
  let(:output_dir) { output_root.join('output') }
  let(:fixtures){ Pathname.new('spec').join('fixtures') }
  let(:complete_dir){ output_dir.join('complete') }
  let(:incomplete_dir){ output_dir.join('incomplete') }
  let(:luminaire) { FactoryGirl.build(:luminaire, ctn: ctn) }

  before do
    ApsLogger.stub(:log)
  end

  describe '.export_all' do
    let(:ctn1){ '162548716' }
    let(:ctn2){ '162548710' }
    let(:luminaire1) do
      FactoryGirl.build(:luminaire, ctn: ctn1).tap do |obj|
        obj.stub(is_complete?:false)
      end
    end
    let(:luminaire2) do
      FactoryGirl.build(:luminaire, ctn: ctn2).tap do |obj|
        obj.stub(is_complete?:true)
      end
    end
    let(:luminaires){ [luminaire1, luminaire2] }
    let(:target_file1){ incomplete_dir.join(luminaire1.fam_name, "#{luminaire1.fam_name}.txt") }
    let(:target_file2){ complete_dir.join(luminaire2.fam_name, "#{luminaire2.fam_name}.txt") }
    subject{ described_class.export_all luminaires, output_dir }
    context 'same family' do
      it 'generates summaries' do
        subject
        target_file1.should exist
        target_file2.should exist
      end
    end
    context 'different family' do
      let(:ctn2){ '123456789' }
      it 'generates summaries' do
        subject
        target_file1.should exist
        target_file2.should exist
      end
    end
  end

  describe '.export' do
    let(:ctn){ '162541289' }
    subject{ described_class.export luminaire, output_dir }
    let(:fixtures){ Pathname.new('spec').join('fixtures') }
    let(:source_file){ fixtures.join('luminaire_summary.txt') }
    let(:target_dir){ incomplete_dir.join('16254') }
    let(:target_file){ target_dir.join('16254.txt') }
    let(:eol) { "\r\n" }

    context 'new file' do
     it 'writes new file' do
      subject
      target_file.should exist
     end
     it 'contains luminaire summary information' do
      subject
      target_file.open.read.should include ctn
      target_file.open.read.should include eol
     end
    end

    context 'existing file' do
      before do
        target_dir.mkpath
        FileUtils.cp source_file,target_file
      end
      it 'generates only one file' do
        subject
        target_dir.entries.select{ |f| target_dir.join(f).file? }.count.should eql 1
      end
      it 'appends to existing content' do
        subject
        target_file.open.read.should include source_file.open.read
      end
    end
  end

  describe '#summary' do
    let(:ctn){ '162548716' }
    let(:materials){ ['60', '262', '262'] }
    let(:reference_file) { '' }
    let(:content){ fixtures.join(reference_file).open.read }
    let(:luminaire) do
      FactoryGirl.build(:luminaire,
                        ctn: ctn,
                        main_material: 'AL',
                        description: 'Dunetop lantern post LED grey 1x7.5W SEL',
                        main_color_description: 'Grey 1',
                        main_material_description: 'Aluminium',
                        nr_of_lightsources:'1',
                        bulb_description: 'MODULE 3 Led\'s White 2700 K',
                        color_temperature: '2700 K',
                        nominal_lumen: '325',
                        rated_lumen: '326',
                        luminous_flux: '271',
                        beam_angle: '60',
                        radiation_pattern: 'lambertian pattern',
                        designated_room: 'Garden & Patio'
      ).tap {|lum| lum.stub(:materials).and_return(materials)}
    end

    subject{ described_class.summary luminaire }

    context 'complete' do
      let(:reference_file) { 'luminaire_summary.txt' }
      it{ should eql content }
    end
    context 'no materials' do
      let(:reference_file){ 'luminaire_summary_missing_colorsheet.txt' }
      let(:materials) { [] }
      it "should log a warning" do
        stub_const("ApsLogger", double())
        ApsLogger.should_receive(:log).twice
        subject
      end
      it{ should eql content }
    end

    context 'empty luminaire' do
      let(:luminaire){ FactoryGirl.build(:luminaire, ctn: ctn) }
      let(:reference_file){ 'luminaire_summary_empty_luminaire.txt' }
      it "should log a warning" do
        stub_const("ApsLogger", double())
        ApsLogger.should_receive(:log).twice
        subject
      end
      it{ should eql content }
    end
  end

end
