module View3D
  def self.filename(family)
    Pathname.new(family).join("#{family}-3DVIEW.JT")
  end

  def self.is_a_view3d?(filename)
    filename.downcase.end_with? ".jt"
  end
end
