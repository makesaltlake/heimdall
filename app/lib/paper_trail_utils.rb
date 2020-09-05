module PaperTrailUtils
  # Adds the specified metadata to
  # PaperTrail.request.controller_info[:metadata], runs the given block, then
  # resets PaperTrail.request.controller_info back to what it was before.
  #
  # This can be used to add PaperTrail metadata to any paper trail records
  # generated while the block is being run.
  def self.with_metadata(metadata, deep_merge: true)
    existing_controller_info = PaperTrail.request.controller_info
    existing_metadata = existing_controller_info&.[](:metadata) || {}
    new_metadata = deep_merge ? existing_metadata.deep_merge(metadata) : existing_metadata.merge(metadata)

    PaperTrail.request.controller_info = (existing_controller_info || {}).merge(metadata: new_metadata)

    begin
      yield
    ensure
      PaperTrail.request.controller_info = existing_controller_info
    end
  end
end
