ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        if authorized?(:read, CertificationIssuance)
          paginated_table_panel(
            CertificationIssuance.accessible_by(current_ability).order(created_at: :desc),
            title: 'Recently issued certifications',
            param_name: :new_certifications_page,
            per_page: 10
          ) do
            column(:description) { |certification_issuance| auto_link(certification_issuance) }
            column(:user) { |certification_issuance| auto_link(certification_issuance.user, certification_issuance.name_of_recipient) }
            column(:certification)
            column(:issued_at)
          end
        end
      end

      column do
        if authorized?(:read_newest_users, User)
          paginated_table_panel(
            User.accessible_by(current_ability).order('subscription_created DESC NULLS LAST'),
            title: 'Recent member signups',
            param_name: :new_members_page,
            per_page: 10
          ) do
            column(:name) { |user| auto_link(user) }
            column(:subscription_created)
            column(:subscription_active)
          end
        end
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
end
