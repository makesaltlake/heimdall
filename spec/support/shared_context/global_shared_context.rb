RSpec.shared_context 'global shared context' do
  let(:admin_user_password) { 'admin_user_password' }
  let(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', password: admin_user_password, super_user: true) }

  let(:normal_user_password) { 'normal_user_password' }
  let(:normal_user) { User.create!(name: 'Normal User', email: 'normal@example.com', password: normal_user_password) }

  let(:member_user_password) { 'member_user_password' }
  let(:member_user) do
    User.create!(
      name: 'Member User',
      email: 'member@example.com',
      password: member_user_password,
      subscription_id: 'test_subscription_id',
      subscription_created: Time.now,
      subscription_active: true
    )
  end

  let(:normal_certification) { Certification.create!(name: 'Normal Certification') }
end