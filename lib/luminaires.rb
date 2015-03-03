require 'roo'
require 'rubyXL'

class Luminaires < Array

  MAPPING1 = {
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

  MAPPING2 = {
    :itemnr                    => 3,
    :ctn                       => 1,
    :description               => 4,
    :part_description          => -1,
    :commercial_name           => 20,
    :designated_room           => 12,
    :main_color_description    => 23,
    :main_material             => 24,
    :main_material_description => 25,
    :nr_of_lightsources        => 56,
    :bulb_description          => 49,
    :color_temperature         => 59,
    :nominal_lumen             => 57,
    :rated_lumen               => 58,
    :luminous_flux             => -1,
    :beam_angle                => 61,
    :radiation_pattern         => -1
  }

  def import_from_excel excel_file
    rows =
      if excel_file.extname.casecmp(".xlsx") == 0
        rows_from_xlsx excel_file
      else
        rows_from_xls excel_file
      end

    mapping =
      if normalize(rows[0][4]) == "Item Description" then
        MAPPING2
      else
        MAPPING1
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

  def rows_from_xlsx file
    workbook = RubyXL::Parser.parse file.to_s
    sheet = workbook[0]
    sheet.extract_data
  end

  def rows_from_xls file
    workbook = Roo::Spreadsheet.open file.to_s
    workbook.default_sheet = workbook.sheets.first
    workbook.to_a
  end

end
