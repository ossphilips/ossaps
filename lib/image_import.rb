require 'net/http'

class ImageImport

  HOST = 'images.philips.com'
  PATH  = '/is/image/PhilipsConsumer/'
  SIZE = 1200
  POSTPARAMETERS = "&op_sharpen=1&qlt=95"
  REF_IMG_TYPES = [:DPP, :RTP, :APP, :A1P, :UPL]
  MIN_IMAGE_LENGTH = 10240
  @@request = Net::HTTP.new(HOST)

  def self.image_path ctn, type, params
    name = "#{ctn}-#{type}-global-001"
    "#{PATH}#{name}?#{params}#{POSTPARAMETERS}"
  end

  def self.download_reference_images ctn, output_dir
    images = []
    REF_IMG_TYPES.each do |type|
      if path = get_reference_path(ctn, type)
        res = @@request.get(path)
        output_dir.mkpath
        file = output_dir.join("#{ctn}-#{type}.jpg")
        file.open("wb") do |f|
          f.write(res.body)
        end
        images.push type: type, file: file
      end
    end
    images
  end

  private

  def self.is_reference_path path
    res = @@request.request_head(path)
    res.is_a?(Net::HTTPOK) and res['content-length'].to_i > MIN_IMAGE_LENGTH
  end

  def self.get_reference_path ctn, type
    ["wid=#{SIZE}", "hei=#{SIZE}"].each do |params|
      path = image_path ctn, type, params
      return path if is_reference_path(path)
    end
    nil
  end
end
