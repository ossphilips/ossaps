require 'spec_helper'
require 'view3d'

describe View3D do
  let(:view3d_file) { 'spec/fixtures/3dview.jt' }
  let(:view3d) { Pathname.new(view3d_file).tap { |pn| pn.extend View3D } }

  describe '#is_a_view3d?' do
    subject { described_class.is_a_view3d?(entry) }
    context 'is a view3d' do
      let(:entry) { 'DOCUMENTS/162548716-915004122901/915004122901-DEVELOPMNT-3DVIEW.088505.JT' }
      it { should be_true }
    end
    context 'is not a view3d' do
      let(:entry) { "invalid" }
      it { should be_false }
    end
  end

  describe '.filename' do
    subject { described_class.filename('16254') }
    it{ should eql Pathname.new('16254').join('16254-3DVIEW.JT')}
  end
end
