-- ============================================================================
-- Migration 005: Word Bank
-- ============================================================================

CREATE TABLE word_bank (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  word            text NOT NULL,
  category        text NOT NULL DEFAULT 'general',
  difficulty      word_difficulty NOT NULL DEFAULT 'medium',
  language        text NOT NULL DEFAULT 'en',
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamptz DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX idx_word_bank_unique ON word_bank (lower(word), category, language);
CREATE INDEX idx_word_bank_selection ON word_bank (difficulty, language, is_active) WHERE is_active = true;
CREATE INDEX idx_word_bank_category ON word_bank (category) WHERE is_active = true;

COMMENT ON TABLE word_bank IS 'Word dictionary for drawing prompts';

-- Seed data
INSERT INTO word_bank (word, category, difficulty) VALUES
  ('cat', 'animals', 'easy'), ('dog', 'animals', 'easy'), ('fish', 'animals', 'easy'),
  ('bird', 'animals', 'easy'), ('sun', 'nature', 'easy'), ('moon', 'nature', 'easy'),
  ('star', 'nature', 'easy'), ('tree', 'nature', 'easy'), ('flower', 'nature', 'easy'),
  ('house', 'objects', 'easy'), ('car', 'objects', 'easy'), ('book', 'objects', 'easy'),
  ('ball', 'objects', 'easy'), ('hat', 'objects', 'easy'), ('cup', 'objects', 'easy'),
  ('apple', 'food', 'easy'), ('pizza', 'food', 'easy'), ('cake', 'food', 'easy'),
  ('banana', 'food', 'easy'), ('ice cream', 'food', 'easy'),
  ('elephant', 'animals', 'medium'), ('penguin', 'animals', 'medium'),
  ('butterfly', 'animals', 'medium'), ('dolphin', 'animals', 'medium'),
  ('guitar', 'objects', 'medium'), ('bicycle', 'objects', 'medium'),
  ('umbrella', 'objects', 'medium'), ('telescope', 'objects', 'medium'),
  ('castle', 'objects', 'medium'), ('volcano', 'nature', 'medium'),
  ('rainbow', 'nature', 'medium'), ('waterfall', 'nature', 'medium'),
  ('hamburger', 'food', 'medium'), ('spaghetti', 'food', 'medium'),
  ('swimming', 'actions', 'medium'), ('dancing', 'actions', 'medium'),
  ('fishing', 'actions', 'medium'), ('cooking', 'actions', 'medium'),
  ('painting', 'actions', 'medium'), ('sleeping', 'actions', 'medium'),
  ('constellation', 'science', 'hard'), ('democracy', 'concepts', 'hard'),
  ('nostalgia', 'concepts', 'hard'), ('camouflage', 'nature', 'hard'),
  ('quicksand', 'nature', 'hard'), ('chandelier', 'objects', 'hard'),
  ('trampoline', 'objects', 'hard'), ('xylophone', 'objects', 'hard'),
  ('accordion', 'objects', 'hard'), ('skyscraper', 'objects', 'hard'),
  ('juggling', 'actions', 'hard'), ('sleepwalking', 'actions', 'hard'),
  ('breakdancing', 'actions', 'hard'), ('archaeology', 'concepts', 'hard'),
  ('ventriloquist', 'concepts', 'hard'), ('kaleidoscope', 'objects', 'hard');
