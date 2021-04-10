ActiveAdmin.register InventoryBin do
  menu parent: 'Inventory', priority: 4

  permit_params :inventory_area_id, :notes

  filter :inventory_area
  filter :id
  filter :notes

  index do
    column(:id) { |inventory_bin| auto_link(inventory_bin) }
    column(:inventory_area)
    column(:notes) { |inventory_bin| truncate(inventory_bin.notes, length: 100, separator: ' ') }
    column(:inventory_item)
  end

  show do
    attributes_table do
      row(:id)
      row(:inventory_area)
      row("URL to program into this bin's NFC tag") { |inventory_bin| link_to(nfc_bin_url(inventory_bin), nfc_bin_url(inventory_bin)) }

      row(:notes) { |inventory_bin| format_multi_line_text(inventory_bin.notes) }
    end

    panel 'Bin Contents' do
      attributes_table_for resource do
        row(:inventory_item)
      end
    end
  end

  form do |f|
    f.inputs do
      f.input(:inventory_area) if resource.new_record?
      f.input(:notes)
    end
    f.actions
  end

  action_item :bulk_create, only: :index do
    link_to 'Create Multiple Inventory Bins at Once', bulk_create_admin_inventory_bins_path
  end

  collection_action :bulk_create, method: [:get, :post] do
    authorize! :create, InventoryBin
    @page_title = "Create Multiple Inventory Bins"

    next if request.get?

    form = params[:forms_bulk_create_inventory_bins]

    unless form[:inventory_area].presence
      flash[:alert] = "Must select an inventory area."
      next
    end

    area = InventoryArea.find(form[:inventory_area])
    authorize! :read, area

    bin_count = form[:bin_count].to_i
    unless bin_count > 0
      flash[:alert] = "Must enter a number of bins to create."
      next
    end

    if bin_count > 100
      flash[:alert] = "Can't create more than 100 bins at a time. (This is mostly to prevent typos; let the MSL tech team know if you'd like this limit raised.)"
      next
    end

    bins = TransactionRetry.transaction do
      bin_count.times.map do
        InventoryBin.create!(inventory_area: area, notes: form[:notes])
      end
    end

    redirect_to finish_bulk_create_admin_inventory_bins_path(start: bins[0].id, count: bin_count), status: :see_other
  end

  collection_action :finish_bulk_create, method: :get do
    @bins = InventoryBin.where('id >= ? and id < ?', params[:start].to_i, params[:start].to_i + params[:count].to_i)
    @bins.each do |bin|
      authorize! :read, bin
    end
  end
end
