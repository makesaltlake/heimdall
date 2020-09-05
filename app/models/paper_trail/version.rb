# This class is defined by the paper_trail gem with nothing but
# PaperTrail::VersionConcern included. We need to customize things a bit more
# than that, though, so we'll define our own copy of it.
module PaperTrail
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern

    ransacker :merge_users_source_id do
      Arel.sql("COALESCE(CAST(#{table_name}.metadata #> '{merge_users, source_id}' AS VARCHAR), '')")
    end
  end
end
