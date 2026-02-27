-- ============================================================================
-- Migration 002: Players Table
-- ============================================================================

CREATE TABLE players (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    text NOT NULL,
  avatar_index    integer DEFAULT 0,
  avatar_color    text DEFAULT '#6C5CE7',
  games_played    integer DEFAULT 0,
  games_won       integer DEFAULT 0,
  total_score     bigint DEFAULT 0,
  best_score      integer DEFAULT 0,
  created_at      timestamptz DEFAULT now() NOT NULL,
  updated_at      timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_players_total_score ON players (total_score DESC);

COMMENT ON TABLE players IS 'Player profiles for SketchRush, auto-created on anonymous auth signup';
