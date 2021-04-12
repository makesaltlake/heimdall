ActiveAdmin.register_page "Statistics" do
  menu priority: 16

  content title: "Statistics" do
    panel "Total members at the end of each month" do
      line_chart MembershipDeltaService.last_by(:month).transform_values(&:total_members)
    end
  end
end
