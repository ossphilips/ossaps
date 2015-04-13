require 'spec_helper'
require 'luminaires'
require 'luminaire'

describe Luminaires do

  let(:lum1){ FactoryGirl.build(:luminaire, ctn: '123456782', commercial_name: 'NAME1') }
  let(:lum2){ FactoryGirl.build(:luminaire, ctn: '123456783', commercial_name: 'NAME2') }
  let(:lum3){ FactoryGirl.build(:luminaire, ctn: '123456781', commercial_name: 'NAME3') }
  let(:lums){ described_class.new << lum1 << lum2 << lum3 }

  describe '#import_from_excel' do

    shared_examples "luminaire importer" do
      let(:file) { Pathname.new('spec').join('fixtures', filename) }
      subject { described_class.new.import_from_excel file }

      its(:size){ should eql 3 }
      it 'contains only luminaire objects' do
        subject.each do |lum|
          lum.should be_a_kind_of Luminaire
        end
      end
      it 'parses all required fields' do
        lum = subject[0]
        keys = ['itemnr', 'description', 'commercial_name', 'designated_room',
                'main_color_description', 'main_material', 'main_material_description',
                'nr_of_lightsources', 'bulb_description', 'color_temperature',
                'nominal_lumen', 'rated_lumen', 'beam_angle'
        ]
        keys.each do |key|
          expected_value = key
          lum.public_method("#{key}").call().should eql expected_value
        end
      end
      it 'parses all optional fields depending on the format' do
        lum = subject[0]

        keys = ['luminous_flux', 'radiation_pattern', 'part_description']
        keys.each do |key|
          expected_value = if format == 1 then key else '' end
          lum.public_method("#{key}").call().should eql expected_value
        end
      end
      it 'strips a all whitespace and null-bytes from the CTN' do
        subject.each do |lum|
          lum.ctn.should eql '123456782'
        end
      end
    end

    context 'xls file' do
       it_behaves_like "luminaire importer" do
         let(:filename) { 'luminaires_format1.xls' }
         let(:format) { 1 }
       end

       it_behaves_like "luminaire importer" do
         let(:filename) { 'luminaires_format2.xls' }
         let(:format) { 2 }
       end
    end

    context 'xlsx file' do
       it_behaves_like "luminaire importer" do
         let(:filename) { 'luminaires_format1.xlsx' }
         let(:format) { 1 }
       end
       it_behaves_like "luminaire importer" do
         let(:filename) { 'luminaires_format2.xlsx' }
         let(:format) { 2 }
       end
    end
  end

  describe '.ctn_hash' do
    subject { lums.ctn_hash }
    it { should be_a_kind_of Hash }
    its(:keys) { should eql lums.map(&:ctn)}
    it 'has they correct luminaires corresponding to the keys' do
      lums.map(&:ctn).each do |ctn|
        subject[ctn].ctn.should eql ctn
      end
    end
  end

  describe '.remove_duplicates' do
    subject{ lums.remove_duplicates }
    context 'no duplicate CTN' do
      context 'no empty rows' do
        its(:size){ should eql 3 }
      end
      context 'empty rows' do
        let(:lum1){ FactoryGirl.build(:luminaire, ctn: '123456781', commercial_name: 'NAME1') }
        let(:lum2){ FactoryGirl.build(:luminaire, ctn: '123456782', commercial_name: '') }
        let(:lum3){ FactoryGirl.build(:luminaire, ctn: '123456783', commercial_name: 'NAME3') }
        its(:size){ should eql 3 }
      end
    end
    context 'duplicate CTN' do
      context 'one with designated room' do
        let(:lum1){ FactoryGirl.build(:luminaire, ctn: '123456781', designated_room: '') }
        let(:lum2){ FactoryGirl.build(:luminaire, ctn: '123456781', designated_room: 'bathroom') }
        let(:lum3){ FactoryGirl.build(:luminaire, ctn: '123456781', designated_room: '') }
        its(:size){ should eql 1 }
        its(:first) { should equal lum2 }
      end
#      context 'same designated rooms and different part names' do
#        let(:lum1){ FactoryGirl.build(:luminaire, ctn: '123456781', part_description: 'NAME2', designated_room: 'bathroom') }
#        let(:lum2){ FactoryGirl.build(:luminaire, ctn: '123456781', part_description: 'NAME1', designated_room: 'bathroom') }
#        let(:lum3){ FactoryGirl.build(:luminaire, ctn: '123456781', part_description: '', designated_room: '') }
#        its(:size){ should eql 1 }
#        it 'keeps the row with the designated room and smallest part_name' do
#          subject.first.part_description.should eql 'NAME1'
#        end
#      end
    end
  end

end
