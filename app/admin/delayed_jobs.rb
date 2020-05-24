ActiveAdmin.register Delayed::Job do
  menu label: 'Delayed Jobs', parent: 'Developer Stuff'

  actions :index, :show

  config.sort_order = 'id_desc'

  filter :id
  filter :tag
  filter :strand

  index title: 'Delayed Jobs' do
    column(:id) { |dj| auto_link(dj, dj.id) }
    column(:created_at)
    column(:run_at)
    column(:locked_at)
    column(:tag)
    column(:strand)
  end

  show do
    attributes_table do
      row(:id)
      row(:created_at)
      row(:run_at)
      row(:locked_at)
      row(:locked_by)
      row(:failed_at)
      row(:tag)
      row(:strand)
      row(:handler) { |dj| pre dj.handler }
      row(:attempts)
      row(:max_attempts)
    end
  end
end
