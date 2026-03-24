-- ============================================================
-- WNYU Archive — Useful Queries
-- ============================================================


-- ------------------------------------------------------------
-- 1. Everything not yet digitized
-- ------------------------------------------------------------
SELECT
    r.id,
    r.artist,
    r.title,
    r.format,
    r.condition,
    r.location
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE d.status = 'pending'
ORDER BY r.artist, r.title;


-- ------------------------------------------------------------
-- 2. Digitization progress summary
-- ------------------------------------------------------------
SELECT
    d.status,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percent
FROM digitization d
GROUP BY d.status
ORDER BY count DESC;


-- ------------------------------------------------------------
-- 3. Search across artist, title, label, and notes at once
--    Replace 'coltrane jazz' with your search terms
-- ------------------------------------------------------------
SELECT
    r.artist,
    r.title,
    r.label,
    r.year,
    r.format,
    d.status AS digitization_status
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE to_tsvector('english',
        COALESCE(r.artist, '') || ' ' ||
        COALESCE(r.title, '') || ' ' ||
        COALESCE(r.label, '') || ' ' ||
        COALESCE(r.notes, '')
      ) @@ to_tsquery('english', 'coltrane & jazz')
ORDER BY r.artist, r.title;


-- ------------------------------------------------------------
-- 4. All records by a specific artist (partial match)
-- ------------------------------------------------------------
SELECT
    r.artist,
    r.title,
    r.year,
    r.format,
    r.condition,
    d.status AS digitization_status
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE r.artist ILIKE '%miles davis%'
ORDER BY r.year;


-- ------------------------------------------------------------
-- 5. Records by genre
--    PostgreSQL arrays let you store multiple genres per record
-- ------------------------------------------------------------
SELECT
    r.artist,
    r.title,
    r.year,
    r.genres,
    d.status AS digitization_status
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE 'jazz' = ANY(r.genres)
ORDER BY r.artist;


-- ------------------------------------------------------------
-- 6. Records in good enough condition to digitize, not yet done
-- ------------------------------------------------------------
SELECT
    r.artist,
    r.title,
    r.format,
    r.condition,
    r.location
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE d.status = 'pending'
  AND r.condition IN ('mint', 'very good', 'good')
ORDER BY r.condition, r.artist;


-- ------------------------------------------------------------
-- 7. Recently digitized records
-- ------------------------------------------------------------
SELECT
    r.artist,
    r.title,
    r.format,
    d.digitized_by,
    d.digitized_at,
    d.file_path
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE d.status = 'done'
ORDER BY d.digitized_at DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 8. Records by decade
-- ------------------------------------------------------------
SELECT
    (r.year / 10) * 10 AS decade,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE d.status = 'done') AS digitized
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE r.year IS NOT NULL
GROUP BY decade
ORDER BY decade;


-- ------------------------------------------------------------
-- 9. Mark a record as digitized
--    Replace 42 with the actual record id
-- ------------------------------------------------------------
UPDATE digitization
SET
    status       = 'done',
    digitized_by = 'your name',
    digitized_at = CURRENT_DATE,
    file_path    = '/archive/flac/artist-title.flac',
    file_format  = 'FLAC'
WHERE record_id = 42;
