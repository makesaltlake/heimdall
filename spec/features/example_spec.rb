RSpec.describe 'an example spec' do
  it 'works' do
    visit '/'
    expect(page).to have_content('Loading...')
  end
end
