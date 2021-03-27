class NfcController < ApplicationController
  def bin
    @bin = InventoryBin.find(params[:id])
  end
end
