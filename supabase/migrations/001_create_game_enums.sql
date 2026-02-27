-- ============================================================================
-- Migration 001: Custom Enum Types
-- SketchRush - Real-time Drawing & Guessing Game
-- ============================================================================

CREATE TYPE room_status AS ENUM (
  'waiting',
  'starting',
  'playing',
  'finished',
  'abandoned'
);

CREATE TYPE game_phase AS ENUM (
  'word_selection',
  'drawing',
  'turn_reveal',
  'round_scores',
  'game_over'
);

CREATE TYPE player_role AS ENUM (
  'drawer',
  'guesser',
  'spectator'
);

CREATE TYPE word_difficulty AS ENUM (
  'easy',
  'medium',
  'hard'
);

CREATE TYPE message_type AS ENUM (
  'guess',
  'correct',
  'close_guess',
  'system',
  'chat'
);
