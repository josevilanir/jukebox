# Lessons Learned

This file contains the history of patterns, corrected mistakes, and rules to prevent recurrence, as per GEMINI.MD.

## Rules & Patterns

### Never call `.count` on a relation with a custom SELECT aggregate
`queue_open` uses `select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")`.
Calling `.count` on it generates `COUNT(queue_items.*, COALESCE(...) AS score)` which is invalid PostgreSQL.
Use `.length` (loads records, counts in Ruby) or `.any?` / `.none?` instead.
