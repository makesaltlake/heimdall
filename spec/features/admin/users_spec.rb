RSpec.describe 'admin/users' do
  before :each do
    login
  end

  it 'allows creating a user without an email address or password' do
    visit new_admin_user_path

    fill_in 'Name', with: 'Joe User'
    click_button 'Create User'

    expect(page).to have_content('User was successfully created')
  end

  it 'requires a password confirmation if a password is specified' do
    visit new_admin_user_path

    fill_in 'Name', with: 'Joe User'
    fill_in 'Email', with: 'joe@example.com'
    fill_in 'user_password', with: 'a test password'
    click_button 'Create User'

    expect(page).to have_content("doesn't match Password")
  end
end
