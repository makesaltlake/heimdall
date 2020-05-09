module PaginatedTableHelpers
  def paginated_table(collection_to_paginate, param_name:, per_page: 25)
    collection_to_paginate = collection_to_paginate.page(params[param_name]).per(per_page)
    paginated_collection(collection_to_paginate, param_name: param_name, download_links: false) do
      table_for(collection) do
        yield
      end
    end
  end

  def paginated_table_panel(collection_to_paginate, title:, param_name:, per_page: 25, &block)
    puts "second instance: #{self.class}"
    panel "#{title} (#{collection_to_paginate.count})" do
      paginated_table(collection_to_paginate, param_name: param_name, per_page: per_page, &block)
    end
  end
end

ActiveAdmin::Views::Pages::Show.include(PaginatedTableHelpers)
