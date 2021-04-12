ActiveAdmin.register_page "Statistics" do
  menu priority: 16

  content title: "Statistics" do
    join_and_loss_counts = MembershipDeltaService.last_with_join_and_loss_counts(:month).transform_keys(&:end_of_month)
    join_and_loss_counts_sans_first_year = Hash[join_and_loss_counts.to_a[12..] || []]

    charts = {
      total_members: {
        title: "Total members at the end of each month",
        chart: -> () { column_chart MembershipDeltaService.last_by(:month).transform_keys(&:to_date).transform_values(&:total_members), height: "75vh" }
      },
      join_count: {
        title: "Total signups during each month (absolute number of members)",
        chart: -> () { column_chart join_and_loss_counts.transform_values(&:join_count), colors: [ChartColors::GREEN], height: "75vh" }
      },
      cancel_count: {
        title: "Total cancellations during each month (absolute number of members)",
        chart: -> () { column_chart join_and_loss_counts.transform_values(&:cancel_count), colors: [ChartColors::RED], height: "75vh" }
      },
      delta_count: {
        title: "Change in membership during each month (absolute number of members)",
        chart: -> () { column_chart join_and_loss_counts.transform_values(&:delta_count), height: "75vh" }
      },
      join_percentage: {
        title: "Total signups during each month (percentage of existing membership base, not including the first 12 months)",
        chart: -> () { column_chart join_and_loss_counts_sans_first_year.transform_values(&:join_percentage), colors: [ChartColors::GREEN], height: "75vh", suffix: "%" }
      },
      cancel_percentage: {
        title: "Total cancellations during each month (percentage of existing membership base, not including the first 12 months)",
        chart: -> () { column_chart join_and_loss_counts_sans_first_year.transform_values(&:cancel_percentage), colors: [ChartColors::RED], height: "75vh", suffix: "%" }
      },
      delta_percentage: {
        title: "Change in membership during each month (percentage of existing membership base, not including the first 12 months)",
        chart: -> () { column_chart join_and_loss_counts_sans_first_year.transform_values(&:delta_percentage), height: "75vh" }
      }
    }.with_indifferent_access

    current_chart = params[:chart] || charts.keys[0]

    form method: :get, action: admin_statistics_path do
      select name: 'chart' do
        charts.each do |slug, chart|
          option chart[:title], value: slug, selected: slug == current_chart
        end
      end

      input type: :submit, value: 'Go'
    end

    chart = charts[current_chart]
    if chart
      text_node instance_exec(&chart[:chart])
    else
      text_node "No such chart"
    end


    # panel "Total members at the end of each month" do
    #   column_chart MembershipDeltaService.last_by(:month).transform_keys(&:to_date).transform_values(&:total_members), height: "37vw"
    # end


    # panel "New member signups during each month (absolute number of members)" do
    #   column_chart join_and_loss_counts.transform_values(&:join_count), colors: [ChartColors::GREEN], height: "75vh"
    # end

    # panel "Membership cancellations during each month (absolute number of members)" do
    #   column_chart join_and_loss_counts.transform_values(&:cancel_count), colors: [ChartColors::RED], height: "75vh"
    # end

    # panel "Change in membership during each month (absolute number of members)" do
    #   column_chart join_and_loss_counts.transform_values(&:delta_count), height: "75vh"
    # end

    # panel "New member signups during each month (percentage of existing membership base, not including the first 12 months)" do
    #   column_chart join_and_loss_counts.transform_values(&:join_percentage), colors: [ChartColors::GREEN], height: "75vh", suffix: "%"
    # end

    # panel "Membership cancellations during each month (percentage of existing membership base, not including the first 12 months)" do
    #   column_chart join_and_loss_counts.transform_values(&:cancel_percentage), colors: [ChartColors::RED], height: "75vh", suffix: "%"
    # end

    # panel "Change in membership during each month (percentage of existing membership base, not including the first 12 months)" do
    #   column_chart join_and_loss_counts.transform_values(&:delta_percentage), height: "75vh"
    # end


  end
end
