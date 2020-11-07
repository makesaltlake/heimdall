# Helpers to generate panels containing paginated tables, all in one go
module PaginatedTableHelpers
  def paginated_table(collection_to_paginate, param_name:, per_page: 25)
    collection_to_paginate = collection_to_paginate.page(params[param_name]).per(per_page)
    paginated_collection(collection_to_paginate, param_name: param_name, download_links: false) do
      table_for(collection) do
        yield
      end
    end
  end

  def paginated_table_panel(collection_to_paginate, title:, param_name:, per_page: 25, header: nil, &block)
    panel title do
      div header if header
      paginated_table(collection_to_paginate, param_name: param_name, per_page: per_page, &block)
    end
  end
end
ActiveAdmin::Views::Pages::Show.include(PaginatedTableHelpers)
ActiveAdmin::Views::Pages::Page.include(PaginatedTableHelpers)

# Helper to display a form field that contains static text inside an AA form
module FixedTextFormHelpers
  def fixed_text(label, text)
    li do
      label(label)
      div(text, style: 'display: inline-block')
    end
  end
end
ActiveAdmin::Views::ActiveAdminForm.include(FixedTextFormHelpers)

# Raise an exception after completing a custom controller action if neither
# `authorize!` nor `no_authorization_needed!` was called. That way it's more
# difficult to make the easy mistake of not authorizing custom controller
# actions.
#
# (Note that calling `resource` from within a `member_action` custom controller
# action automatically calls `authorize!` using the controller action's name as
# the permission to check for, so no explicit permission check is needed if
# that's the right behavior.)
module ActiveAdminResourceDSLAuthorizationChecks
  def member_action(*args, &block)
    super(*args) do |*action_args|
      begin
        instance_exec(*action_args, &block)
      ensure
        raise "neither authorize! nor no_authorization_needed! were called. please fix your custom controller action." unless @aah_authorization_happened
      end
    end
  end

  def collection_action(*args, &block)
    super(*args) do |*action_args|
      begin
        instance_exec(*action_args, &block)
      ensure
        raise "neither authorize! nor no_authorization_needed! were called. please fix your custom controller action." unless @aah_authorization_happened
      end
    end
  end
end
ActiveAdmin::ResourceDSL.prepend(ActiveAdminResourceDSLAuthorizationChecks)
module ActiveAdminResourceControllerAuthorizationChecks
  def authorize!(*args)
    @aah_authorization_happened = true
    super
  end

  def no_authorization_needed!
    @aah_authorization_happened = true
  end
end
ActiveAdmin::ResourceController.prepend(ActiveAdminResourceControllerAuthorizationChecks)

# Helpers for rendering and uploading Active Storage image attachments
module ActiveAdminActiveStorageShowHelper
  def active_storage_input_row(attribute)
    row(attribute) do |resource|
      attachment = resource.send(attribute)
      if attachment.attached?
        a href: url_for(attachment) do
          image_tag attachment.variant(resize_to_limit: [150, 150])
        end
      end
    end
  end
end
ActiveAdmin::Views::Pages::Show.include(ActiveAdminActiveStorageShowHelper)
module ActiveAdminActiveStorageFormHelper
  def active_storage_input(form, attribute)
    attachment = form.object.send(attribute)
    if attachment.attached?
      hint = "Existing image:<br/><img src=\"#{CGI.escapeHTML(url_for(attachment.variant(resize_to_limit: [150, 150])))}\"/>".html_safe
    else
      hint = nil
    end

    form.input(attribute, as: :file, hint: hint)
  end
end
ActiveAdmin::Views::ActiveAdminForm.include(ActiveAdminActiveStorageFormHelper)
