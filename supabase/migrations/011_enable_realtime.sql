-- ============================================================================
-- Migration 011: Enable Realtime for specific tables
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE game_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE room_players;
