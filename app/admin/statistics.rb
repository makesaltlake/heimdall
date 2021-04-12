ActiveAdmin.register_page "Statistics" do
  menu priority: 16

  content title: "Statistics" do
    panel "Total members at the end of each month" do
      column_chart MembershipDeltaService.last_by(:month).transform_keys(&:to_date).transform_values(&:total_members), height: "37vw"
    end

    join_and_loss_counts = MembershipDeltaService.last_with_join_and_loss_counts(:month).transform_keys(&:end_of_month)

    panel "New member signups during each month (absolute number of members)" do
      column_chart join_and_loss_counts.transform_values(&:join_count), colors: [ChartColors::GREEN], height: "40vw"
    end

    panel "Membership cancellations during each month (absolute number of members)" do
      column_chart join_and_loss_counts.transform_values(&:cancel_count), colors: [ChartColors::RED], height: "40vw"
    end

    panel "New member signups during each month (percentage of existing membership base)" do
      column_chart join_and_loss_counts.transform_values(&:join_percentage), colors: [ChartColors::GREEN], height: "40vw", suffix: "%"
    end

    panel "Membership cancellations during each month (percentage of existing membership base)" do
      column_chart join_and_loss_counts.transform_values(&:cancel_percentage), colors: [ChartColors::RED], height: "40vw", suffix: "%"
    end
  end
end
