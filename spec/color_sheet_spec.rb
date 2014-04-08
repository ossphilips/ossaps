require 'spec_helper'
require 'color_sheet'
require 'aps_logger'
require 'roo'

describe ColorSheet do
  let(:colorsheet){ Pathname.new 'spec/fixtures/colorsheet.xls' }

  describe '.import' do
    subject { described_class.new.import colorsheet}

    context 'massive colorsheet' do
      let(:colorsheet) { 'spec/fixtures/colorsheet.xls' }
      its(:used_materials) { should == { '31' => ['A309', '60', 'K309'],
                                         '87' => ['F263', '60', 'K263'], '' => [] } }
    end
    context 'colorsheet with text' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_with_text.xls' }
      its(:used_materials) { should == { '31' => ['A309', 'A309', 'AO88','60','31','A309', 'NO switch NEW exploded view will be created'],
                                         ''=>['Date', '2011-09-12'] } }
    end
    context 'colorsheet with footer' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_with_footer.xls' }
      its(:used_materials) { should == { '' => ['Date'],
                                         '93' => ['56', 'G252'] } }
    end
    context 'empty colorsheet' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_empty.xls' }
      its(:used_materials) { should == { } }
    end
    context 'colorsheet 31607' do
      let(:colorsheet) { 'spec/fixtures/31607-COLORSHEET.XLS' }
      its(:used_materials) { should == { '48' => ['C60', '69', 'C921'],
                                         '' =>["Date", '2012-12-22'] } }
    end
    context 'colorsheet 40731' do
      let(:colorsheet) { 'spec/fixtures/40731-COLORSHEET.XLS' }
      its(:used_materials) { should == { '86' => ['31', 'C895', 'C846'],
                                         '48' => ['31', 'C259', 'C962'],
                                         '31' => ['31', 'A309', 'A398'],
                                         '' => ['Date', '2011-02-18'] }
      }
    end
    context 'colorsheet 30852' do
      let(:colorsheet) { 'spec/fixtures/30852-COLORSHEET.XLS' }
      its(:used_materials) { should == { '31' => ['56', '302', 'color with Newline'],
                                         '11' => ['56', 'AO88'],
                                         '' => ['Date'] }
      }
    end
    context 'Uses the second worksheet if more than 1 worksheet exist' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_with_multiple_sheets.xls' }
      its(:used_materials) { should == { '86' => ['31', 'C895', 'C846'],
                                         '48' => ['31', 'C259', 'C962'],
                                         '31' => ['31', 'A309', 'A398'],
                                         '' => ['Date', '2011-02-18'] }
      }
    end
    context 'Stops parsing if another color is encountered in the same column' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_with_stacked_colors.xls' }
      its(:used_materials) { should == { '86' => ['31', 'C895', 'C846'],
                                         '48' => ['31', 'C259', 'C962'],
                                         '31' => ['31', 'A309', 'A398'],
                                         '' => ['Date', '2011-02-18'],
                                         '1' => ['2', '3', '4'],
                                         '5' => ['6', '7', '8'] }
      }
    end
  end

  describe '.used_materials_by_color' do
    subject { described_class.new.import(colorsheet) }
    context 'massive colorsheet' do
      let(:colorsheet) { 'spec/fixtures/colorsheet.xls' }
      it 'has the expected materials' do
        subject.used_materials_by_color('31').should eql ['A309', '60', 'K309']
        subject.used_materials_by_color('87').should eql ['F263', '60', 'K263']
      end
    end
    context 'colorsheet with only one color' do
      let(:colorsheet) { 'spec/fixtures/colorsheet_with_only_one_color.xls' }
      it 'has the expected materials' do
        subject.used_materials_by_color('31').should eql ['31', 'C259', 'C962']
        subject.used_materials_by_color('87').should eql ['31', 'C259', 'C962']
      end
    end
  end

  describe '#is_a_colorsheet?' do
    subject { described_class.is_a_colorsheet?(entry) }
    context 'is a colorsheet' do
      let(:entry) { 'DOCUMENTS/162548716-915004122901/915004122901-DEVELOPMNT-COLORSHEET.CD112416.XLS'}
      it { should be_true }
    end
    context 'is not a colorsheet' do
      let(:entry) { 'invalid' }
      it { should be_false }
    end
  end

  describe '#filename' do
    subject{ described_class.filename('16254') }
    it{ should eql Pathname.new('16254').join('16254-COLORSHEET.XLS')}
  end
end
