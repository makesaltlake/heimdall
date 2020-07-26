# == Schema Information
#
# Table name: badge_access_grants
#
#  id              :text             primary key
#  access_reason   :text
#  badge_reader_id :bigint
#  user_id         :bigint
#
class BadgeAccessGrant < ApplicationRecord
  # NOTE: This model is actually a view. You can't modify it. If you need to
  # change any of the logic that goes into computing what users can access what
  # badge readers, you'll want to find the most recent migration that updated
  # the badge_access_grants_view, make a copy of it, then tweak the SQL with
  # whatever changes you need to make and run it (and make sure to include a
  # #down in the migration that sets it back to whatever SQL it used in the
  # migration just before).
  #
  # It's worth noting that the view is only moderately efficient. We may see a
  # bit of slowdown as new members join and get certified and we may want to
  # rethink if there's a better way of computing access; we could for example
  # compute and store access on a per-user basis and only recompute it when
  # anything that goes into whether that user has access changes. It's tricky
  # to get that set of conditions right, of course, without creating a lot of
  # tech debt in the process: one example is that adding user A to user B's
  # household requires recomputing access of both users in A's new household as
  # well as users in A's old household, and marking a user's subscription as
  # cancelled requires recomputing access for all of that user's household
  # members.
  #
  # (One possible thing that could help out with the above problem is to have a
  # job that kicks off nightly that recomputes access for everyone and warns if
  # that resulted in a change of access - since that would mean that some
  # condition changed that didn't properly kick off a regeneration when it
  # happened. At any rate, access control would be guaranteed to be up to date
  # on a nightly basis even if there were bugs in the logic that kicked off
  # regenerations.)
  #
  # ---
  #
  # Also, before doing any of the above optimizations, we should create a
  # dashboard that reports on expensive queries so that we can see if and when
  # this actually becomes a problem.
  def readonly?
    true
  end

  # this is a synthetic combination of the badge reader id and the user id that
  # we define in the view
  self.primary_key = 'id'

  belongs_to :user
  belongs_to :badge_reader
end
