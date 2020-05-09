ActiveAdmin.register BadgeReader do
  menu parent: 'Badge Readers', priority: 1

  permit_params :name, :description

  filter :name

  index do
    column(:name) { |badge_reader| auto_link(badge_reader) }
    column(:description)
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |badge_reader| format_multi_line_text(badge_reader.description) }
      row(:api_token) { |badge_reader| link_to('Reveal', '/todo') }
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:description)
    end
    f.actions
  end
end
