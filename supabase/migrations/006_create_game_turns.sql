-- ============================================================================
-- Migration 006: Game Turns
-- ============================================================================

CREATE TABLE game_turns (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         uuid NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  round_number    integer NOT NULL,
  turn_number     integer NOT NULL,
  drawer_id       uuid NOT NULL REFERENCES players(id),
  word_choices    text[] NOT NULL DEFAULT '{}',
  chosen_word     text,
  word_hint       text,
  started_at      timestamptz,
  ends_at         timestamptz,
  ended_at        timestamptz,
  guessers_total  integer DEFAULT 0,
  correct_guesses integer DEFAULT 0,
  drawer_score    integer DEFAULT 0,
  turn_data       jsonb DEFAULT '{}',
  created_at      timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_game_turns_room ON game_turns (room_id, round_number, turn_number);
CREATE INDEX idx_game_turns_active ON game_turns (room_id, started_at) WHERE ended_at IS NULL;

COMMENT ON TABLE game_turns IS 'Per-turn state: drawer, word, timing, and scoring results';
