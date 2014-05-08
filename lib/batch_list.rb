require 'zip/zip'
require 'fileutils'
require_relative 'luminaire'
require_relative 'luminaires'
require_relative 'color_sheet'
require_relative 'view3d'
require_relative 'csv_exporter'
require_relative 'image_import'
require_relative 'aps_logger'
require_relative 'summary_exporter'

class BatchList

  def initialize input_dir, output_dir
    @output_dir = Pathname.new(output_dir)
    @output_dir.mkpath unless @output_dir.exist?
    input_dir = Pathname.new(input_dir)

    @logger = ApsLogger.new output_dir.join("error_log.txt")

    excel_files = Pathname.glob(input_dir.join( "*.{xls,XLS,xlsx,XLSX}"))
    ApsLogger.log :fatal, "Found more then one Excel file in directory #{input_dir}" if excel_files.size > 1
    @excel_file = excel_files.first
    ApsLogger.log :fatal, "Excel file missing in directory #{input_dir}" unless @excel_file

    zip_files = Pathname.glob(input_dir.join("*.{zip,ZIP}"))
    ApsLogger.log :fatal, "Found more then one Zipfile in directory #{input_dir}" if zip_files.size > 1
    @zip_file = zip_files.first
    ApsLogger.log :fatal, "Zipfile missing in directory #{input_dir}" unless @zip_file
  end

  def self.enrich_luminaires zip_file, luminaires, output_dir
    luminaires_hash = luminaires.ctn_hash
    colorsheets = {}
    view3ds = {}
    Zip::ZipFile.open(zip_file) do |zip|
      zip.each do |entry|
        name = entry.name
        if entry.file? && name =~ /(\w+)-(\d+)?\/\2?/
          ctn = $1
          fam = Luminaire.ctn2fam_name(ctn)
          lum = luminaires_hash[ctn]
          ApsLogger.log :warn, "No entry in Excel file for #{name} (ctn #{ctn})"  unless lum
          path = Pathname.new(name)
          if ColorSheet.is_a_colorsheet?(name)
            file = output_dir + ColorSheet.filename(fam, path.extname())
            extract(entry, file)
            colorsheets[fam] ||= ColorSheet.new
            colorsheets[fam].import(file)
            ApsLogger.log :info, "Colorsheet added for family #{fam}"
          elsif View3D.is_a_view3d?(name)
            if !view3ds[fam]
              file = output_dir + View3D.filename(fam, path.extname())
              extract(entry, file)
              view3ds[fam] = file.extend View3D
              ApsLogger.log :info, "View3D added for family #{fam}"
            end
          elsif name.downcase.include? ".jpg"
            file = output_dir + fam + ctn  + path.basename
            extract(entry, file)
            if lum
              lum.reference_images.push type: :ref, file: file
            end
            ApsLogger.log :info, "Reference image added for #{ctn}"
          end
        end
      end
    end

    luminaires.each do |lum|
      lum.colorsheet = colorsheets[lum.fam_name]
      lum.view3d = view3ds[lum.fam_name]
    end
  end

  def self.download_reference_images luminaires, output_dir
    luminaires.each do |lum|
      lum.reference_images.concat ImageImport.download_reference_images lum.ctn, output_dir.join(lum.fam_name, lum.ctn)
    end
  end

  def process
    luminaires = Luminaires.new.import_from_excel(@excel_file).remove_duplicates
    luminaires_dir = @output_dir.join('luminaires')
    self.class.enrich_luminaires @zip_file, luminaires, luminaires_dir
    self.class.download_reference_images luminaires, luminaires_dir
    SummaryExporter.export_all luminaires, luminaires_dir
    CsvExporter.export_all luminaires, @output_dir.join("luminaires.csv")
  end

  private

  def self.extract(entry, file)
    file.dirname.mkpath
    entry.extract(file) { true }
    file.utime(file.atime, entry.mtime)
  end
end
