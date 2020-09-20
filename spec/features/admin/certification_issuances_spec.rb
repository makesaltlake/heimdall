RSpec.describe 'admin/certification_issuances' do
  before :each do
    login
  end

  it 'allows issuing certifications' do
    normal_certification
    member_user

    visit admin_certification_issuances_path
    click_on 'Issue a Certification'

    select normal_certification.name, from: 'Certification'
    select_in_dynamic_dropdown member_user.name, from: 'User'

    click_on 'Create Certification issuance'

    issuance = member_user.reload.certification_issuances.take
    expect(issuance.certification).to eq(normal_certification)
    expect(issuance).to be_active
  end

  it 'allows revoking certifications' do
    normal_certification
    member_user

    member_user.certification_issuances.create!(certification: normal_certification)

    visit admin_certification_issuance_path(member_user.certification_issuances[0])
    click_on 'Revoke'

    fill_in 'Revocation reason', with: 'Test revocation reason'
    click_on 'Revoke'

    expect(member_user.reload.certification_issuances[0]).to_not be_active
  end
end
