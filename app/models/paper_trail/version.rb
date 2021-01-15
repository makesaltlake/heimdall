# == Schema Information
#
# Table name: versions
#
#  id             :bigint           not null, primary key
#  event          :string           not null
#  item_type      :string           not null
#  metadata       :jsonb
#  object         :jsonb
#  object_changes :jsonb
#  whodunnit      :string
#  created_at     :datetime
#  item_id        :bigint           not null
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#  index_versions_on_metadata               (metadata) USING gin
#  index_versions_on_object                 (object) USING gin
#  index_versions_on_object_changes         (object_changes) USING gin
#

# This class is defined by the paper_trail gem with nothing but
# PaperTrail::VersionConcern included. We need to customize things a bit more
# than that, though, so we'll define our own copy of it.
module PaperTrail
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern

    scope :changes_made_by_humans, -> { where.not(whodunnit: nil) }
    scope :changes_made_by_machines_or_other_automated_processes, -> { where(whodunnit: nil) }

    ransacker :merge_users_source_id do
      Arel.sql("COALESCE(CAST(#{table_name}.metadata #> '{merge_users, source_id}' AS VARCHAR), '')")
    end
  end
end
