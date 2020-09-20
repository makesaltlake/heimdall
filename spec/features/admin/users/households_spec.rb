RSpec.describe 'admin/users/households' do
  it 'detects membership across households' do
    login

    member_user
    normal_user

    visit admin_users_path
    expect(find('.col-name', text: member_user.name).sibling('.col-household_has_membership')).to have_content('YES')
    expect(find('.col-name', text: normal_user.name).sibling('.col-household_has_membership')).to have_content('NO')

    visit edit_admin_user_path(member_user)

    select_in_dynamic_dropdown normal_user.name, from: 'Household members'
    click_on 'Update User'

    visit admin_users_path
    expect(find('.col-name', text: member_user.name).sibling('.col-household_has_membership')).to have_content('YES')
    expect(find('.col-name', text: normal_user.name).sibling('.col-household_has_membership')).to have_content('YES')
  end
end
