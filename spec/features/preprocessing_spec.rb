require 'spec_helper'

describe 'PreProcessing script' do
  subject { rake_task }

  let(:rake_task) { `rake aps:process #{args_string} 2>&1` }
  let(:input_dir){ Pathname.new('spec/fixtures/input_dir') }
  let(:output_dir){ Pathname.new('tmp/test/output') }
  let(:args_string) { args.map { |k, v| "#{k}=#{v}" }.join(' ') }
  let(:incomplete_dir) { output_dir.join('incomplete') }
  let(:complete_dir) { output_dir.join('complete') }
  let(:complete_luminaires){ ['162548716'] }
  let(:complete_families){ complete_luminaires.map{|ctn| ctn[0,5]}.uniq }
  let(:available_colorsheet_families){ ['16254'] }
  let(:available_view3d_families){ ['16254','16321'] }
  let(:incomplete_luminaires){ ['163218716','163219316','016520616','579403116','579423116','579443116'] }
  let(:incomplete_families){ incomplete_luminaires.map{|ctn| ctn[0,5]}.uniq }
  let(:families){ directory.children.select{|entry| entry.directory?} }
  let(:family_names){ families.map{|entry| entry.basename.to_s} }

  before do
    FileUtils.mkdir_p output_dir
  end

  context 'invalid use' do
    context 'no arguments' do
      let(:args){ {} }
      it{ should include "[ERROR]"}
    end
    context 'missing arguments' do
      let(:args) do
        {
          'OUTPUT_DIR' => "'#{output_dir}'"
        }
      end
      it{ should include "[ERROR]"}
    end
  end

  context 'invalid input' do
    before do
      subject
    end
    let(:args) do
      {
        'INPUT_DIR' => 'invalid_dir',
        'OUTPUT_DIR' => "'#{output_dir}'"
      }
    end

    it 'generates an error log file' do
        output_dir.join('error_log.txt').exist?.should be_true
    end
  end

  context 'valid use' do
    before do
      subject
    end
    let(:args) do
      {
        'INPUT_DIR' => "'#{input_dir}'",
        'OUTPUT_DIR' => "'#{output_dir}'"
      }
    end

    # We combine all the checks because triggering the rake task
    # for each small test takes too much time
    it 'has complete / incomplete directories' do
      output_dir.children.select{|entry| entry.directory?}.count.should eql 2
      output_dir.join('complete').exist?.should be_true
      output_dir.join('incomplete').exist?.should be_true
    end

    context 'complete' do
      let(:directory){ complete_dir }
      let(:luminaires){ complete_luminaires }
      it 'check family directories' do
        family_names.should include *complete_families
      end

      it 'check if luminaires are stored in right directory' do
        families.each do |family|
          family_name = family.basename.to_s
          family.children.select{|entry| entry.directory?}.each do |luminaire|

            ctn = luminaire.basename.to_s

            # Check if luminaire is stored in corresponding family name
            ctn.should include (family_name)

            # Check if list of luminaires contains current ctn
            luminaires.should include ctn
          end
        end
      end

      it 'Check available files' do
        luminaires.each do |ctn|
          family = ctn[0,5]
          directory.join(family,"#{family}-COLORSHEET.XLS").exist?.should be_true
          directory.join(family,"#{family}-3DVIEW.JT").exist?.should be_true
          directory.join(family,"#{family}.txt").exist?.should be_true
        end
      end

      it 'Check used materials in summary files' do
        luminaires.each do |ctn|
          family = ctn[0,5]
          content = File.open(directory.join(family,"#{family}.txt")).read
          content.should include("Used materials: 60, 262, 262")
        end
      end

      it 'copies reference images in the input to the output folder for that luminaire' do
        luminaire_dir = directory.join('16254','162548716')
        luminaire_dir.join('ref1.jpg').size?.should equal 9
        luminaire_dir.join('ref2.JPG').size?.should equal 9
      end

    end

    context 'incomplete' do
      let(:directory){ incomplete_dir }
      let(:luminaires){ incomplete_luminaires }
      it 'check family directories' do
        family_names.should include *incomplete_families
      end

      it 'check if luminaires are stored in right directory' do
        families.each do |family|
          family_name = family.basename.to_s
          family.children.select{|entry| entry.directory?}.each do |luminaire|

            ctn = luminaire.basename.to_s

            # Check if luminaire is stored in corresponding family name
            ctn.should include (family_name)

            # Check if list of luminaires contains current ctn
            luminaires.should include ctn
          end
        end
      end

      it 'Check available summary files' do
        luminaires.each do |ctn|
          family = ctn[0,5]
          directory.join(family,"#{family}.txt").exist?.should be_true
        end
      end

      it 'copies reference images in the input to the output folder for that luminaire' do
        luminaire_dir = directory.join('16321').join('163219316')
        luminaire_dir.join('ref1.jpg').size?.should eq(9)
        luminaire_dir.join('ref2.JPG').size?.should eq(9)
      end
    end

    context 'top level files' do
      it 'generates a csv file' do
        output_dir.join('luminaires.csv').exist?.should be_true
      end
    end

  end
end
