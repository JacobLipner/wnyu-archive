-- ============================================================
-- WNYU Radio Archive — PostgreSQL Schema
-- ============================================================

-- Records: one row per physical item in the archive
CREATE TABLE records (
    id          SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    artist      TEXT NOT NULL,
    label       TEXT,
    catalog_number TEXT,             -- the label's catalog number printed on the record
    format      TEXT CHECK(format IN ('vinyl 7"', 'vinyl 10"', 'vinyl 12"', 'vinyl LP', 'CD', 'cassette', 'other')),
    year        INTEGER CHECK(year > 1800 AND year <= EXTRACT(YEAR FROM NOW())),
    genres      TEXT[],              -- e.g. ARRAY['jazz', 'bebop']
    condition   TEXT CHECK(condition IN ('mint', 'very good', 'good', 'fair', 'poor')),
    location    TEXT,                -- physical location in the archive, e.g. 'Shelf A3'
    barcode     TEXT UNIQUE,
    notes       TEXT,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- Digitization: tracks the status of each record's digitization
CREATE TABLE digitization (
    id              SERIAL PRIMARY KEY,
    record_id       INTEGER NOT NULL REFERENCES records(id) ON DELETE CASCADE,
    status          TEXT NOT NULL DEFAULT 'pending'
                        CHECK(status IN ('pending', 'in_progress', 'done', 'skipped')),
    digitized_by    TEXT,
    digitized_at    DATE,
    file_path       TEXT,            -- where the digital file lives, e.g. '/archive/vinyl/miles-davis-kind-of-blue.flac'
    file_format     TEXT CHECK(file_format IN ('FLAC', 'WAV', 'MP3', 'AAC', 'other')),
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- One digitization row per record (enforced)
CREATE UNIQUE INDEX one_digitization_per_record ON digitization(record_id);

-- ============================================================
-- Full-text search index
-- Lets you search across artist, title, label, and notes at once
-- ============================================================
CREATE INDEX records_fts ON records
    USING GIN (
        to_tsvector('english', 
            COALESCE(artist, '') || ' ' || 
            COALESCE(title, '') || ' ' || 
            COALESCE(label, '') || ' ' || 
            COALESCE(notes, '')
        )
    );

-- ============================================================
-- Helpful indexes for common lookups
-- ============================================================
CREATE INDEX idx_records_artist  ON records(artist);
CREATE INDEX idx_records_format  ON records(format);
CREATE INDEX idx_records_year    ON records(year);
CREATE INDEX idx_digitization_status ON digitization(status);

-- ============================================================
-- Auto-update updated_at on any change
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER records_updated_at
    BEFORE UPDATE ON records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER digitization_updated_at
    BEFORE UPDATE ON digitization
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed: insert a digitization row for every new record automatically
-- So every record starts as 'pending' without manual inserts
-- ============================================================
CREATE OR REPLACE FUNCTION auto_create_digitization()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO digitization (record_id, status) VALUES (NEW.id, 'pending');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER new_record_digitization
    AFTER INSERT ON records
    FOR EACH ROW EXECUTE FUNCTION auto_create_digitization();
