RSpec.shared_context 'feature spec shared context' do
  def login(user: admin_user, password: admin_user_password)
    # TODO: This could be sped up by using Warden::Test::Helpers which manipulates the session instead of actually
    # visiting the login page. It would be interesting to change this to use that and benchmark how much that speeds up
    # tests. Note that if we do that, we should probably add a test that actually runs through the login page to make
    # sure it has coverage.
    visit '/admin/login'

    fill_in 'Email', with: user.email
    fill_in 'Password', with: password

    click_button 'Login'
  end

  # Helper to choose an option from an activeadmin_addons select2 dropdown. Use like:
  #
  # select_in_dynamic_dropdown('Member User', from: 'Recipient')
  #
  # to find the select for a field labeled "Recipient", search for "Member User", and pick the first matching option.
  def select_in_dynamic_dropdown(search_text, from:)
    open_select2(from)
    fill_in_select2_search_field(search_text)
    choose_first_select2_option
  end

  def open_select2(field)
    find(:select, field).sibling('.select2-container').click
  end

  def select2_search_field
    find('.select2-search__field')
  end

  def fill_in_select2_search_field(text)
    select2_search_field.set(text)
  end

  def choose_first_select2_option
    first('.select2-results__option:not(.loading-results):not(.select2-results__message)').click
  end
end
