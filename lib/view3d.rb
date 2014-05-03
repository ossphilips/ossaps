module View3D
  def self.filename(family, ext)
    Pathname.new(family).join("#{family}-3DVIEW#{ext.upcase}")
  end

  def self.is_a_view3d?(filename)
    filename[/(.jt|.stp)\z/i]
  end
end
