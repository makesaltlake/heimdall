# A mixin for any API controller representing a resource that has firmware bundles. It provides a controller method,
# `firmware_blob`, that serves the active firmware for the resource in question.
module Api::Ext::HasFirmware
  def firmware_blob
    firmware_bundle = resource.firmware_bundles.active.take

    if firmware_bundle
      redirect_to url_for(firmware_bundle.firmware_blob)
    else
      render status: 404, plain: 'No active firmware bundle'
    end
  end
end
