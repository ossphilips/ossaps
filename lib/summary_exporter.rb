require_relative 'aps_logger'

class SummaryExporter

  def self.export luminaire, output_dir
    target_dir = output_dir.join(luminaire.is_complete? ? 'complete' : 'incomplete', luminaire.fam_name)
    target_dir.mkpath
    target_file = target_dir.join("#{luminaire.fam_name}.txt")
    target_file.open('a+') do |file|
      file.write summary(luminaire).gsub(/\n/,"\r\n")
    end
  end

  def self.export_all luminaires, output_dir
    luminaires.each do |luminaire|
      export luminaire, output_dir
    end
  end

  def self.summary luminaire
    if luminaire.materials.empty?
      # this validation should actually be moved to the batchlist
      ApsLogger.log :warn, "Materials missing for Luminaire #{luminaire.ctn}"

      if !luminaire.has_colorsheet?
         ApsLogger.log :warn, "Colorsheet missing for Luminaire #{luminaire.ctn}"
      end
    end

    strip_heredoc <<-FILE
      -----\* #{luminaire.ctn} \*-----
      Description: #{luminaire.description}
      Main Color: #{luminaire.main_color}
      Main Color Description: #{luminaire.main_color_description}
      Main Material: #{luminaire.main_material}
      Main Material Description: #{luminaire.main_material_description}
      Used materials: #{luminaire.materials.join(", ")}
      Number of light sources: #{luminaire.nr_of_lightsources}
      Bulb description: #{luminaire.bulb_description}
      Colour Temperature: #{luminaire.color_temperature}
      Lumen per light source: #{luminaire.nominal_lumen}
      Luminous flux per light source: #{luminaire.luminous_flux}
      Beam Angle: #{luminaire.beam_angle}
      Radiation Pattern: #{luminaire.radiation_pattern}
      Room: #{luminaire.designated_room}


    FILE
  end

  def self.strip_heredoc(string)
    indent = string.scan(/^[ \t]*(?=\S)/).min.size || 0
    string.gsub(/^[ \t]{#{indent}}/, '')
  end

end
