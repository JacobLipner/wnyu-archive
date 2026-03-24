-- ============================================================
-- WNYU Archive — Sample Data
-- A few example records to test your setup
-- ============================================================

INSERT INTO records (title, artist, label, catalog_number, format, year, genres, condition, location, notes)
VALUES
    ('Kind of Blue',        'Miles Davis',      'Columbia',     'CL 1355',   'vinyl LP',   1959, ARRAY['jazz'],              'very good', 'Shelf A1', NULL),
    ('A Love Supreme',      'John Coltrane',    'Impulse!',     'A-77',      'vinyl LP',   1965, ARRAY['jazz', 'avant-garde'],'good',      'Shelf A1', 'Slight surface noise on side 2'),
    ('Remain in Light',     'Talking Heads',    'Sire',         'SRK 6095',  'vinyl LP',   1980, ARRAY['new wave', 'funk'],   'very good', 'Shelf B3', NULL),
    ('Purple Rain',         'Prince',           'Warner Bros',  '25110-1',   'vinyl LP',   1984, ARRAY['pop', 'rock', 'funk'],'mint',      'Shelf B4', 'Still sealed'),
    ('Nevermind',           'Nirvana',          'DGC',          'DGC-24425', 'CD',         1991, ARRAY['rock', 'grunge'],     'good',      'Shelf C2', NULL),
    ('Illmatic',            'Nas',              'Columbia',     'CK 57684',  'CD',         1994, ARRAY['hip-hop'],            'very good', 'Shelf C5', NULL),
    ('Blue Lines',          'Massive Attack',   'Wild Bunch',   'WBRX 1',    'vinyl LP',   1991, ARRAY['trip-hop'],           'good',      'Shelf B5', NULL),
    ('Dummy',               'Portishead',       'Go! Discs',    '828 522-1', 'vinyl LP',   1994, ARRAY['trip-hop'],           'very good', 'Shelf B5', NULL);

-- Note: digitization rows are created automatically by the trigger
-- Update a couple to show different statuses
UPDATE digitization SET status = 'done', digitized_by = 'archive team', digitized_at = '2025-06-01', file_path = '/archive/flac/miles-davis-kind-of-blue.flac', file_format = 'FLAC'
WHERE record_id = (SELECT id FROM records WHERE title = 'Kind of Blue');

UPDATE digitization SET status = 'in_progress', digitized_by = 'archive team'
WHERE record_id = (SELECT id FROM records WHERE title = 'A Love Supreme');
