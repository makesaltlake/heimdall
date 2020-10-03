RSpec.describe UserMergeService do
  subject { described_class.new(normal_user, normal_user_2, admin_user) }

  it 'transfers subscriptions' do
    subscription = normal_user.stripe_subscriptions.create!(active: true)

    subject.run!

    expect(subscription.reload.user).to eq(normal_user_2)
  end
end
