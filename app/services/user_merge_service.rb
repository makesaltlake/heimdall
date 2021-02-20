# A service that can merge two users together.
#
# Use like so:
#
# UserMergeService.new(source_user, target_user, user_kicking_off_the_merge).run!
#
# That will transfer all of source_user's certifications to target_user, move
# all of source_user's household members to target_user's household, etc.,
# etc., and then finally source_user will be deleted.
#
# ---
#
# To add an additional step in the merge process, add a `step` block to the
# class that contains the steps to perform. Steps are run in the order they
# are defined and are really just a convenient way to break out the merge
# logic into separate methods without having to invoke all of the methods in
# `run!` and keep the method definitions and the method calls in sync as steps
# are added or reordered. Oh, and their descriptions are shown on the admin
# page where user merges are kicked off, too.
#
# Note that all steps are run inside a single database transaction; that way
# if one step fails the entire user merge will be aborted.
#
# Also note that `whodunnit` is only used for things like setting the user
# that revoked a duplicated certification; it is *not* explicitly given to
# PaperTrail to use as the whodunnit for any changes made: the expectation is
# that this service will be invoked from a controller action where `whodunnit`
# has already been set into PaperTrail automatically.
class UserMergeService
  attr_reader :source, :target, :whodunnit
  class_attribute :steps

  def initialize(source, target, whodunnit)
    @source = source
    @target = target
    @whodunnit = whodunnit
  end

  private_class_method def self.step(description, &block)
    (self.steps ||= []) << OpenStruct.new(description: description, block: block)
  end

  def run!
    raise "You can't merge a user with themselves" if source == target

    user = TransactionRetry.transaction do
      PaperTrailUtils.with_metadata({ merge_users: { source_id: source.id, target_id: target.id } }) do
        self.class.steps.each do |step|
          self.instance_exec(&step.block)
        rescue
          # Log an error to the Rails console; Sentry should track this error
          # at any rate, but just in case.
          Rails.logger.warn("Warning: an exception occurred while merging users in the #{step.description.inspect} step. This means there's probably a bug in the user merge logic.")
          raise
        end
      end
    end
  end

  # And now for the nitty gritty user merge logic.
  #
  # TODO: There are a few steps we should add, like:
  #   - Copy the source user's badge to the target user if the target user doesn't have one
  #   - Copy the source user's super user status to the target user if the target user isn't a super user
  #   - (maybe) Copy the source user's email address to the target user if the target user doesn't have one
  #   - Merge the two users' Stripe subscription status (won't be needed once we track subscriptions individually in Heimdall and can transfer them directly from the source to the target)
  #     - (in the mean time, we're kicking off a Stripe re-sync during the merge to get this to eventually be right)

  step "transfer the source user's household members to the target user's household" do
    target.household_user_ids = target.household_user_ids | source.household_user_ids
    target.save!
  end

  step "transfer the source user's certification issuances to the target user, revoking any certifications the source user holds if the target user also holds them" do
    source.certification_issuances.find_each do |issuance|
      if issuance.active? && target.certification_issuances.active.where(certification: issuance.certification).exists?
        issuance.revoke!(whodunnit, "This certification issuance was revoked automatically while merging two users together since both users had active, duplicate issuances for the same certification.")
      end
      issuance.update!(user: target)
    end
  end

  step "transfer records about which certifications the source user has issued and records about which certifications the source user has revoked to the target user" do
    update_all(CertificationIssuance, :certifier)
    update_all(CertificationIssuance, :revoked_by)
  end

  step "transfer records about which certifications the source user instructs to the target user" do
    update_all_or_destroy_if_not_unique(CertificationInstructor, :user)
  end

  step "if a badge is currently being programmed for the source user by a badge writer, switch it to program a badge for the target user instead" do
    update_all(BadgeWriter, :currently_programming_user)
    update_all(BadgeWriter, :last_programmed_user)
  end

  step "transfer all badge scans from the source user to the target user" do
    update_all(BadgeScan, :user)
  end

  step "transfer records about any badge readers to which the source user has been granted manual access to the target user" do
    update_all_or_destroy_if_not_unique(BadgeReaderManualUser, :user)
  end

  step "transfer the source user's subscriptions to the target user" do
    update_all(StripeSubscription, :user)
  end

  step "delete the source user" do
    source.destroy!
  end

  # And then some helpers for the merge process.

  private def update_all(scope, attribute)
    scope.where(attribute => source).find_each { |o| o.update!(attribute => target) }
  end

  private def update_all_or_destroy_if_not_unique(scope, attribute)
    scope.where(attribute => source).find_each do |o|
      o.update!(attribute => target)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      Rails.logger.info("While merging source user #{source.id} into target user #{target.id}, #{o.class} ##{o.id} couldn't be transferred to the target user. We're assuming this is because the target user has a conflicting record; this one will be destroyed.")
      o.destroy!
    end
  end
end
