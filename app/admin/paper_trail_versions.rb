ActiveAdmin.register PaperTrail::Version do
  menu parent: 'Developer Stuff'

  actions :index, :show

  config.sort_order = 'id_desc'

  filter :item_type
  filter :item_id, label: 'Item ID'
  filter :created_at

  scope :all, default: :true
  scope :changes_made_by_humans
  scope :changes_made_by_machines_or_other_automated_processes

  index do
    column(:event) { |version| auto_link(version, version.event) }
    column(:item) do |version|
      if version.item
        auto_link(version.item)
      else
        "#{version.item_type} ##{version.item_id}"
      end
    end
    column(:author) { |version| paper_trail_version_author(version) }
    column(:created_at)
  end

  show do
    previous_for_all = PaperTrail::Version.where('id < ?', resource.id).order(id: :desc).first
    next_for_all = PaperTrail::Version.where('id > ?', resource.id).order(id: :asc).first

    previous_link_for_self = link_to '<', resource_path(resource.previous), title: 'Previous version for this resource' if resource.previous
    previous_link_for_all = link_to '<<', resource_path(previous_for_all), title: 'Previous version for any resource in the system' if previous_for_all
    next_link_for_all = link_to '>>', resource_path(next_for_all), title: 'Next version for any resource in the system' if next_for_all
    next_link_for_self = link_to '>', resource_path(resource.next), title: 'Next version for this resource' if resource.next

    div do
      div style: 'float: right' do
        safe_join([next_link_for_self, next_link_for_all].compact, '&nbsp;&nbsp;&nbsp;'.html_safe)
      end
      div do
        safe_join([previous_link_for_all, previous_link_for_self].compact, '&nbsp;&nbsp;&nbsp;'.html_safe)
      end
    end

    attributes_table do
      row(:event)
      row(:item_type)
      row('Item ID', &:item_id)
      row(:item)
      row(:author) { |version| paper_trail_version_author(version, show_unknown: true) }
      row(:created_at)
    end

    panel 'Changes' do
      table_for resource.object_changes.to_a.sort do
        column(:attribute) { |change| change[0] }
        column(:before) { |change| change[1][0] }
        column(:after) { |change| change[1][1] }
      end
    end

    panel 'Metadata' do
      pre JSON.pretty_generate(resource.metadata)
    end
  end
end
