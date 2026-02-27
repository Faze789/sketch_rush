-- ============================================================================
-- Migration 012: Add rounds_won to room_players
-- ============================================================================

ALTER TABLE room_players
  ADD COLUMN rounds_won integer NOT NULL DEFAULT 0;

COMMENT ON COLUMN room_players.rounds_won IS 'Number of rounds this player won (highest round score)';
