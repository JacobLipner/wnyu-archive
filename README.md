# WNYU Radio Archive

A PostgreSQL database for cataloging and tracking the digitization of WNYU's physical record collection (vinyl, CDs, cassettes).

## What it does

- Catalogs every physical record in the archive with metadata (artist, title, label, format, condition, location, genres)
- Tracks the digitization status of each record (pending → in progress → done)
- Full-text search across artist, title, label, and notes
- Automatically creates a digitization tracking row for every new record added

## Project structure

```
wnyu-archive/
├── schema.sql           # All tables, indexes, and triggers — run this first
├── queries/
│   └── queries.sql      # Useful queries for searching and reporting
├── data/
│   └── sample_data.sql  # A few example records to test your setup
└── README.md
```

## Setup

### Prerequisites

- PostgreSQL 13 or higher
- `psql` command line tool

### Create the database and run the schema

```bash
createdb wnyu_archive
psql wnyu_archive < schema.sql
```

### (Optional) Load sample data

```bash
psql wnyu_archive < data/sample_data.sql
```

### Connect and start querying

```bash
psql wnyu_archive
```

## Example queries

**See everything not yet digitized:**
```sql
SELECT r.artist, r.title, r.format, r.location
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE d.status = 'pending'
ORDER BY r.artist;
```

**Search across all fields:**
```sql
SELECT r.artist, r.title, r.label, d.status
FROM records r
JOIN digitization d ON r.id = d.record_id
WHERE to_tsvector('english', r.artist || ' ' || r.title || ' ' || COALESCE(r.label, '') || ' ' || COALESCE(r.notes, ''))
      @@ to_tsquery('english', 'coltrane & jazz');
```

**Digitization progress:**
```sql
SELECT status, COUNT(*) FROM digitization GROUP BY status;
```

**Mark a record as digitized:**
```sql
UPDATE digitization
SET status = 'done', digitized_by = 'your name', digitized_at = CURRENT_DATE,
    file_path = '/archive/flac/artist-title.flac', file_format = 'FLAC'
WHERE record_id = 42;
```

See `queries/queries.sql` for the full set of useful queries.

## Schema overview

### `records`
One row per physical item. Key fields:

| Column | Description |
|---|---|
| `artist`, `title` | Required |
| `format` | vinyl 7", vinyl LP, CD, cassette, etc. |
| `genres` | PostgreSQL array — e.g. `ARRAY['jazz', 'bebop']` |
| `condition` | mint / very good / good / fair / poor |
| `location` | Physical shelf location in the archive |
| `catalog_number` | Label's catalog number printed on the record |
| `barcode` | For scanning CDs to auto-pull metadata |

### `digitization`
One row per record, created automatically when a record is added. Key fields:

| Column | Description |
|---|---|
| `status` | pending / in_progress / done / skipped |
| `digitized_by` | Who did the digitization |
| `digitized_at` | Date completed |
| `file_path` | Where the digital file lives |
| `file_format` | FLAC / WAV / MP3 / AAC |
