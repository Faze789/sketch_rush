-- ============================================================================
-- Migration 004: Room Players (Join Table)
-- ============================================================================

CREATE TABLE room_players (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         uuid NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  player_id       uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  display_name    text NOT NULL,
  avatar_index    integer DEFAULT 0,
  avatar_color    text DEFAULT '#6C5CE7',
  score           integer NOT NULL DEFAULT 0,
  turn_order      integer NOT NULL DEFAULT 0,
  role            player_role NOT NULL DEFAULT 'guesser',
  has_guessed     boolean NOT NULL DEFAULT false,
  is_connected    boolean NOT NULL DEFAULT true,
  is_ready        boolean NOT NULL DEFAULT false,
  correct_guesses integer DEFAULT 0,
  drawings_done   integer DEFAULT 0,
  joined_at       timestamptz DEFAULT now() NOT NULL,
  left_at         timestamptz
);

CREATE UNIQUE INDEX idx_room_players_unique
  ON room_players (room_id, player_id)
  WHERE left_at IS NULL;

CREATE INDEX idx_room_players_room ON room_players (room_id, turn_order)
  WHERE left_at IS NULL;

CREATE INDEX idx_room_players_active ON room_players (player_id)
  WHERE left_at IS NULL;

COMMENT ON TABLE room_players IS 'Player membership and per-game scores within rooms';
