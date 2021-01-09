module WaiverForeverUtils
  # Generate a URL to WaiverForever's web interface for the waiver with the specified ID. Note that this works only for
  # waivers that have been approved; WaiverForever uses a separate URL for ones that are pending that this method
  # doesn't account for.
  def self.waiver_url(waiver_id)
    "https://app.waiverforever.com/get_signed_doc/#{waiver_id}"
  end
end
