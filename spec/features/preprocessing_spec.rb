require 'spec_helper'

describe 'PreProcessing script' do
  subject { rake_task }

  let(:rake_task) { `rake aps:process #{args_string} 2>&1` }
  let(:input_dir){ Pathname.new('spec/fixtures/input_dir') }
  let(:output_dir) { Pathname.new('tmp/features/output') }
  let(:args_string) { args.map { |k, v| "#{k}=#{v}" }.join(' ') }
  let(:luminaires_dir) { output_dir.join('luminaires') }
  let(:available_colorsheet_families){ ['16254'] }
  let(:available_view3d_families){ ['16254','16321'] }
  let(:luminaires){ ['162548716','163218716','163219316','016520616','579403116','579423116','579443116'] }
  let(:families){ luminaires.map{|ctn| ctn[0,5]}.uniq }
  let(:family_dirs){ luminaires_dir.children.select{|entry| entry.directory?} }
  let(:family_names){ family_dirs.map{|entry| entry.basename.to_s} }
  let(:args) { {'INPUT_DIR' => "'#{input_dir}'", 'OUTPUT_DIR' => "'#{output_dir}'"} }
  before do
    FileUtils.mkdir_p output_dir
  end

  context 'invalid use' do
    context 'no arguments' do
      let(:args){ {} }
      it{ should include "[ERROR]"}
    end
    context 'missing arguments' do
      let(:args) { {'OUTPUT_DIR' => "'#{output_dir}'"} }
      it{ should include "[ERROR]"}
    end
  end

  context 'invalid input' do
    let(:input_dir) { 'invalid_dir' }
    before do
      subject
    end
    it 'generates an error log file' do
      output_dir.join('error_log.txt').exist?.should be_true
    end
  end

  context 'valid use' do
    # We combine all the checks because triggering the rake task
    # for each small test takes too much time
    # not allowed to use subject of let in before and after blocks
    before(:all) do
      @output_dir = Pathname.new('tmp/features/output')
      @result = `rake aps:process INPUT_DIR='spec/fixtures/input_dir' OUTPUT_DIR="#{@output_dir}"`
    end

    after(:all) do
      @output_dir.rmtree
    end

    it 'creates a luminaires directory' do
      output_dir.children.select{|entry| entry.directory?}.count.should eql 1
      luminaires_dir.exist?.should be_true
    end

    it 'creates all family directories' do
      family_names.should include *families
    end

    it 'generates summary file for each family' do
      luminaires.each do |ctn|
        family = ctn[0,5]
        luminaires_dir.join(family,"#{family}.txt").exist?.should be_true
      end
    end

    it 'creates a directory in the family directory of each luminaire' do
      family_dirs.each do |family|
        family_name = family.basename.to_s
        family.children.select{|entry| entry.directory?}.each do |luminaire|

          ctn = luminaire.basename.to_s

          # Check if luminaire is stored in corresponding family name
          ctn.should include family_name

          # Check if list of luminaires contains current ctn
          luminaires.should include ctn
        end
      end
    end

    it 'generates colorsheet, cad file and summary files for complete luminaires' do
      ctn = '162548716'
      family = ctn[0,5]
      family_dir = luminaires_dir.join(family)
      ["-COLORSHEET.XLS", "-3DVIEW.JT", ".txt"].each do |postfix|
        family_dir.join("#{family}#{postfix}").exist?.should be_true
      end
    end

    it 'copies reference images in the input to the output folder for that luminaire' do
      ctn = '162548716'
      family = ctn[0,5]
      dir = luminaires_dir.join(family, ctn)
      ['jpg', 'JPG', 'bmp', 'gif', 'tif'].each do |ext|
        dir.join("ref.#{ext}").size?.should equal 9
      end
    end

    it 'has used materials in summary file when colorsheet present' do
      ctn = '162548716'
      family = ctn[0,5]
      content = File.open(luminaires_dir.join(family,"#{family}.txt")).read
      content.should include("Used materials: 60, 262, 262")
    end

    it 'generates a csv file' do
      output_dir.join('luminaires.csv').exist?.should be_true
    end
  end
end
