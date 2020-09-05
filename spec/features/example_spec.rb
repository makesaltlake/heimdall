RSpec.describe 'an example spec' do
  it 'works' do
    visit '/'
    expect(page).to have_content('You need to sign in or sign up before continuing')
  end
end
