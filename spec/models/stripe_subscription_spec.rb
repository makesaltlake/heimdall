RSpec.describe StripeSubscription do
  context 'user updates' do
    let!(:subscription) do
      expect(normal_user.subscription_active).to be(false)
      expect(normal_user.subscription_created).to be(nil)

      normal_user.stripe_subscriptions.create!(
        active: true,
        unpaid: false,
        customer_email: normal_user.email,
        started_at: Time.now,
        subscription_id_in_stripe: 'test_subscription_id'
      )
    end

    it "updates the user's subscription status when created" do
      normal_user.reload
      expect(normal_user.subscription_active).to be(true)
      expect(normal_user.subscription_created).to eq(subscription.started_at)
      expect(normal_user.subscription_id).to eq(subscription.subscription_id_in_stripe)
    end

    it "shows the user as not subscribed when their subscription is unpaid" do
      subscription.update!(active: false, unpaid: true)

      normal_user.reload
      expect(normal_user.subscription_active).to be(false)
    end

    it "shows the user as not subscribed when their subscription is deactivated" do
      subscription.update!(active: false)

      normal_user.reload
      expect(normal_user.subscription_active).to be(false)
    end

    it "shows the user as not subscribed when their subscription is transferred to someone else" do
      expect(admin_user.subscription_active).to be(false)

      subscription.update!(user: admin_user)

      normal_user.reload
      admin_user.reload
      expect(normal_user.subscription_active).to be(false)
      expect(admin_user.subscription_active).to be(true)
    end

    it "shows the user as not subscribed when their subscription is destroyed" do
      subscription.destroy!

      normal_user.reload
      expect(normal_user.subscription_active).to be(false)
    end
  end
end
