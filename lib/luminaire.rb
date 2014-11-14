require_relative 'aps_logger'

class Luminaire

  DESIGNATED_ROOMS = [
    'BATH Bathroom',
    'FUNC Functional',
    'G&P Garden & Patio',
    'HO&S Home office & Study',
    'KIDS Kids room',
    'KITCH Kitchen',
    'L&B Living- & Bedroom'
  ]

  attr_accessor :ctn
  attr_accessor :view3d
  attr_accessor :colorsheet
  attr_accessor :itemnr
  attr_accessor :description
  attr_accessor :part_description
  attr_accessor :main_color_description
  attr_accessor :main_material
  attr_accessor :main_material_description
  attr_accessor :nr_of_lightsources
  attr_accessor :bulb_description
  attr_accessor :color_temperature
  attr_accessor :nominal_lumen
  attr_accessor :rated_lumen
  attr_accessor :luminous_flux
  attr_accessor :beam_angle
  attr_accessor :radiation_pattern
  attr_accessor :designated_room
  attr_accessor :commercial_name
  attr_reader :reference_images

  def initialize
    # invariant: reference_images!=nil
    @reference_images = []
  end

  def materials
    return [] unless colorsheet
    colorsheet.used_materials_by_color(main_color)
  end

  def has_used_materials?
    !materials.nil? and !materials.empty?
  end

  def has_reference_images?
    reference_images.length > 0
  end

  # returns a boolean
  def has_colorsheet?
    !colorsheet.nil?
  end

  # returns a boolean
  def has_view3d?
    !view3d.nil?
  end

  def has_designated_room?
    DESIGNATED_ROOMS.include?(designated_room)
  end

  def is_complete?
      !ctn.nil? and \
      !itemnr.nil? and \
      has_colorsheet? and \
      has_view3d? and \
      has_used_materials? and \
      has_reference_images? and \
      has_designated_room?
  end

  def main_color
    ctn[5..6]
  end

  def fam_name
    Luminaire.ctn2fam_name(ctn)
  end

  def self.ctn2fam_name(ctn)
    (ctn and ctn.size >= 5) ? ctn[0..4] : ''
  end
end
