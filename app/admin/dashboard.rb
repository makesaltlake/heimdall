ActiveAdmin.register_page "Dashboard" do
  menu priority: 1

  content title: "Dashboard" do
    columns do
      if authorized?(:read, CertificationIssuance)
        column do
          paginated_table_panel(
            CertificationIssuance.accessible_by(current_ability).order(created_at: :desc),
            title: 'Recently issued certifications',
            param_name: :new_certifications_page,
            per_page: 10
          ) do
            column(:description) { |certification_issuance| auto_link(certification_issuance) }
            column(:issued_at)
            column(:user_has_membership) { |certification_issuance| certification_issuance.user&.has_household_membership }
          end
        end
      end

      if authorized?(:read_newest_users, User)
        column do
          paginated_table_panel(
            User.accessible_by(current_ability).includes(:waivers).most_recently_subscribed_first,
            title: 'Recent member signups',
            param_name: :new_members_page,
            per_page: 10
          ) do
            column(:name) { |user| auto_link(user) }
            column(:subscription_created)
            column(:subscription_active)
            column(:has_signed_a_waiver) do |user|
              # Both `user.waivers.exists?` and `user.waivers.count > 0` force AR to
              # hit the database and thwart our efforts to avoid an N+1 by preloading
              # `waivers` in the controller's `scoped_collection` below. Calling
              # `first` instead avoids this. TODO: figure out if there's a good way to
              # force `exists?` or `count` to use whatever's been preloaded rather
              # than trying to hit the database from scratch each time.
              !!user.waivers.first
            end
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
