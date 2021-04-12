ActiveAdmin.register_page "Statistics" do
  menu priority: 16

  content title: "Statistics" do
    panel "Total members at the end of each month" do
      column_chart MembershipDeltaService.last_by(:month).transform_keys(&:to_date).transform_values(&:total_members), height: "40vw"
    end

    panel "New member signups during each month" do
      column_chart StripeSubscription.group_by_month(:started_at).count.transform_keys(&:end_of_month), colors: [ChartColors::GREEN], height: "40vw"
    end

    panel "Membership cancellations during each month" do
      column_chart StripeSubscription.where.not(ended_at: nil).group_by_month(:ended_at).count.transform_keys(&:end_of_month), colors: [ChartColors::RED], height: "40vw"
    end
  end
end
