# PaperTrail audit trail for the review demo.
#
# Each versioned model names its own version class (Review::Version, table
# review_versions) via `has_paper_trail versions: { class_name: ... }`, so the
# gem's default `versions` table is never used and a later demo can keep its
# own history without colliding with this one. Whodunnit comes from
# Review::BaseController#user_for_paper_trail (the session role).
PaperTrail.config.enabled = true
