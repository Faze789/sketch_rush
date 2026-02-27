-- ============================================================================
-- Migration 003: Game Rooms Table
-- ============================================================================

CREATE TABLE game_rooms (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code       text NOT NULL UNIQUE,
  host_id         uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  room_name       text NOT NULL DEFAULT 'SketchRush Room',
  max_players     integer NOT NULL DEFAULT 8 CHECK (max_players BETWEEN 2 AND 12),
  total_rounds    integer NOT NULL DEFAULT 3 CHECK (total_rounds BETWEEN 1 AND 10),
  turn_duration   integer NOT NULL DEFAULT 80 CHECK (turn_duration BETWEEN 30 AND 180),
  word_count      integer NOT NULL DEFAULT 3 CHECK (word_count BETWEEN 2 AND 5),
  difficulty      word_difficulty NOT NULL DEFAULT 'medium',
  is_public       boolean NOT NULL DEFAULT true,
  custom_words    text[] DEFAULT '{}',
  hint_interval   integer NOT NULL DEFAULT 15,
  status          room_status NOT NULL DEFAULT 'waiting',
  current_phase   game_phase,
  current_round   integer DEFAULT 0,
  current_turn    integer DEFAULT 0,
  current_drawer_id uuid REFERENCES players(id),
  game_started_at timestamptz,
  game_ended_at   timestamptz,
  created_at      timestamptz DEFAULT now() NOT NULL,
  updated_at      timestamptz DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX idx_game_rooms_code ON game_rooms (room_code);

CREATE INDEX idx_game_rooms_public_waiting
  ON game_rooms (status, is_public, created_at DESC)
  WHERE is_public = true AND status = 'waiting';

CREATE INDEX idx_game_rooms_host ON game_rooms (host_id, status);

COMMENT ON TABLE game_rooms IS 'Game room configuration and live game state';
