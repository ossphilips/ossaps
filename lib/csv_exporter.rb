class CsvExporter

  def self.to_row lum
    [lum.ctn, lum.fam_name, lum.itemnr, lum.has_colorsheet?.to_s, lum.has_view3d?.to_s, lum.has_designated_room?.to_s, lum.is_complete?.to_s]
  end

  def self.export_all luminaires, output_path
    require 'csv'
    ApsLogger.log :fatal, "Outputpath missing for creating CVS file"  unless output_path
    CSV.open(output_path, "w+b") do |csv|
      csv << HEADER
      luminaires.each do |luminaire|
        csv << (to_row luminaire) unless !luminaire.is_a?(Luminaire)
      end
    end
  end

  HEADER = ["CTN", "Fam name", "Item nbr", "Has Colorsheet", "Has 3DView", "Has designated room", "Complete?"]

end
