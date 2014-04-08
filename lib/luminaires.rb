require 'roo'
require 'rubyXL'

class Luminaires < Array

  def import_from_excel excel_file
    mapping = {
      :itemnr                    => 0,
      :ctn                       => 1,
      :description               => 3,
      :part_description          => 9,
      :commercial_name           => 13,
      :designated_room           => 19,
      :main_color_description    => 27,
      :main_material             => 28,
      :main_material_description => 29,
      :nr_of_lightsources        => 33,
      :bulb_description          => 41,
      :color_temperature         => 50,
      :nominal_lumen             => 52,
      :rated_lumen               => 53,
      :luminous_flux             => 54,
      :beam_angle                => 55,
      :radiation_pattern         => 58
    }
    if excel_file.extname.casecmp(".xlsx") == 0
      workbook = RubyXL::Parser.parse excel_file.to_s
      sheet = workbook[0]
      rows = sheet.extract_data
    else
      workbook = Roo::Spreadsheet.open excel_file.to_s
      workbook.default_sheet = workbook.sheets.first
      rows = workbook.to_a
    end
    # remove header row
    rows.slice!(0)
    rows.each do |row|
      self << Luminaire.new.tap do |lum|
        mapping.each do  |key,value|
          lum.public_method("#{key}=").call(normalize(row[value]))
        end
      end
    end
    self
  end

  def ctn_hash
    Hash[ map { |lum| [lum.ctn, lum] } ]
  end

  # removes Luminaires which contain partial information unless there is no full row available
  def remove_duplicates
    sort_by!{ |lum| [lum.ctn, lum.designated_room, lum.part_description] }
    reverse!
    uniq!{|lum| lum.ctn}
    self
  end

  private

  def normalize v
    v = v.to_i if v.is_a?(Float)
    v.to_s.strip.gsub(/\0/, '')
  end

end
