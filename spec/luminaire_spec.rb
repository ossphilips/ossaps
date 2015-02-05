require 'spec_helper'
require 'luminaire'

describe Luminaire do

  let(:ctn) { '162539316' }
  let(:itemnr){ '915004122801' }
  let(:colorsheet) { nil }
  let(:luminaire){ FactoryGirl.build(:luminaire, ctn: ctn, itemnr: itemnr, colorsheet: colorsheet) }

  describe '#initialize' do
    subject { described_class.new() }
    its(:reference_images) { should be_empty }
  end

  describe '#fam_name' do
    subject{ luminaire.fam_name }
    {'162539316' => '16253', '162'=> '', '' => '', nil => ''}.each do |ctn, fam_name|
      context "with ctn: \'#{ctn.nil? ? 'nil' : ctn}\'" do
        let(:ctn) { ctn }
        it{ should eql fam_name }
      end
    end
  end

  describe '.ctn2fam_name' do
    subject{ Luminaire.ctn2fam_name(ctn) }
    {'162539316' => '16253', '162'=> '', '' => '', nil => ''}.each do |ctn, fam_name|
      context "with ctn: \'#{ctn.nil? ? 'nil' : ctn}\'" do
        let(:ctn) { ctn }
        it{ should eql fam_name }
      end
    end
  end

  describe '#materials' do
    subject{ luminaire.materials }
    context 'without colorsheet' do
      let(:materials){ [] }
      let(:colorsheet) { nil }
      it{ should eql materials }
    end
    context 'with colorsheet' do
      let(:materials){ ['60', '262', '262'] }
      let(:colorsheet) do
        c = double('colorsheet')
        c.stub(:used_materials_by_color).and_return(materials)
        c
      end
      it{ should eql materials }
    end
  end

  describe '#luminaire attributes' do
    subject { luminaire }
    [ :description, :main_color, :main_color_description, :main_material, :main_material_description,
      :nr_of_lightsources, :bulb_description, :color_temperature, :nominal_lumen, :rated_lumen, :luminous_flux,
      :beam_angle, :radiation_pattern, :designated_room, :commercial_name
    ].each do |accessor|
      it{ should respond_to accessor }
    end
  end

  describe '#has_colorsheet' do
    let(:colorsheet){ double('ColorSheet') }
    before do
      luminaire.colorsheet = colorsheet
    end
    subject{ luminaire.has_colorsheet?}
    context 'with colorsheet' do
      it{ should be_true}
    end
    context 'no colorsheet' do
      let(:colorsheet){ nil}
      it{ should be_false}
    end
  end

  describe '#has_view3d' do
    let(:view3d){ double('View3D') }
    before do
      luminaire.view3d = view3d
    end
    subject{ luminaire.has_view3d? }
    context 'with 3D View' do
      it{ should be_true}
    end
    context 'without 3D View' do
      let(:view3d){ nil }
      it{ should be_false}
    end
  end

  describe '#has_used_materials?' do
    let(:materials){ ['material1','material2'] }
    before do
      luminaire.stub(:materials).and_return(materials)
    end
    subject{ luminaire.has_used_materials? }
    context 'multiple materials' do
      it{ should be_true }
    end
    context 'single material' do
      let(:materials){ ['material3'] }
      it{ should be_true }
    end
    context 'no materials' do
      let(:materials){ nil }
      it{ should be_false }
    end
    context 'empty materials' do
      let(:materials){ [] }
      it{ should be_false }
    end
  end

  describe '#has_reference_images?' do
    let(:images){ [{'imagetype1' => 'url1'}, {'imagetype2' =>'url2'}] }
    before do
      luminaire.reference_images.concat images
    end
    subject{ luminaire.has_reference_images? }
    context 'multiple images' do
      it{ should be_true}
    end

    context 'single image' do
      let(:images) { [{ 'imagetype1' => 'url1' }] }
      it { should be_true }
    end

    context 'no reference images' do
      let(:images){ [] }
      it { should be_false }
    end
  end

  describe '#is_complete?' do
    let(:has_colorsheet){ true }
    let(:view3d){ true }
    let(:has_used_materials){ true }
    let(:images){ true }
    let(:has_designated_room) { true }
    subject{ luminaire.is_complete? }
    before do
      luminaire.stub(:has_colorsheet?).and_return(has_colorsheet)
      luminaire.stub(:has_view3d?).and_return(view3d)
      luminaire.stub(:has_used_materials?).and_return(has_used_materials)
      luminaire.stub(:has_reference_images?).and_return(images)
      luminaire.stub(:has_designated_room?).and_return(has_designated_room)
    end
    context 'complete' do
      it{ should be_true}
    end
    context 'no colorsheet ' do
      let(:has_colorsheet){ false }
      it{ should be_false}
    end
    context 'no 3D view' do
      let(:view3d){ false }
      it{ should be_false}
    end
    context 'no materials' do
      let(:has_used_materials){ false }
      it{ should be_false}
    end
    context 'no images' do
      let(:images){ false }
      it{ should be_false}
    end
    context 'no designated room' do
      let(:has_designated_room) { false }
      it{ should be_false}
    end
  end

  describe '#main_color' do
    subject{ luminaire.main_color }
    context 'with ctn' do
      it{ should eql '93'}
    end
  end

  describe '#has_designated_room?' do
    subject{ luminaire.has_designated_room? }
    before do
      luminaire.designated_room = designated_room
      stub_const("Luminaire::DESIGNATED_ROOMS",['foo'])
    end
    {foo: true, bar: false}.each do |value, result|
      describe 'only returns true for known designated rooms' do
        let(:designated_room) { value.to_s }
        it{ should eql result }
      end
    end
  end
end
