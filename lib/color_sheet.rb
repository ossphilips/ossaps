require 'roo'
require_relative 'aps_logger'

class ColorSheet

  attr_accessor :used_materials

  def initialize
    @used_materials = {}
  end

  def import file
    begin
      spreadsheet = Roo::Spreadsheet.open file.to_s
      spreadsheet.default_sheet = spreadsheet.sheets[spreadsheet.sheets.length > 1 ?  1  : 0]
      parse_used_materials spreadsheet
    rescue Exception => e
      #ApsLogger.log :warn, "Error parsing colorsheet #{file}: #{e}"
    end
    self
  end

  def self.filename(family, ext)
    Pathname.new(family).join("#{family}-COLORSHEET#{ext.upcase}")
  end

  def used_materials_by_color color
    materials = @used_materials[color]
    materials = @used_materials[''] if materials.nil? and @used_materials.count == 1
    materials.nil? ?  [] : materials
  end

  def self.is_a_colorsheet? filename
    filename[/(.xlsx|.xls)\z/i]
  end

  private

  # Put all color definitions in the color sheet in a Hash
  # Its colors are the keys
  # Its values are arrays with the materials associated with that color
  def parse_used_materials spreadsheet
    last_row = spreadsheet.last_row
    last_col = spreadsheet.last_column
    first_row = spreadsheet.first_row
    first_col = spreadsheet.first_column
    for row in first_row..last_row do
      for col in first_col..last_col do
          parse_color spreadsheet, row, col, last_row, last_col
      end
    end
  end

  # Find a color definition starting from this row and column
  # The value right below the heading is the color
  # All values below the color are the materials
  def parse_color spreadsheet, row, col, last_row, last_col
    if color_heading? cell(spreadsheet, row, col)
      if row < last_row
        color = color_key cell(spreadsheet, row + 1, col)
        @used_materials[color] ||= []
        for r in row + 2..last_row do
          material = cell(spreadsheet, r, col)
          break if color_heading? material
          @used_materials[color].push strip(material) if !material.empty?
        end
      end
    end
  end

  def strip value
    value.gsub(/[\t\n]/, ' ')
  end

  def color_key value
    value =~ /(\d+)/ ? $1 : value
  end

  def cell spreadsheet, row, col
   value = spreadsheet.cell row,col
   value = value.to_i if value.is_a?(Float)
   value.to_s
  end

  def color_heading? value
    value =~ /Color \d+/i
  end
end
