-- ============================================================================
-- Migration 008: Row Level Security Policies
-- ============================================================================

ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_turns ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Helper function: check room membership without triggering RLS on room_players
-- (avoids infinite recursion when room_players SELECT policy references itself)
CREATE OR REPLACE FUNCTION is_room_member(p_room_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM room_players
    WHERE room_id = p_room_id AND player_id = auth.uid() AND left_at IS NULL
  );
END;
$$ LANGUAGE plpgsql;

-- PLAYERS
CREATE POLICY players_select_all ON players FOR SELECT TO authenticated USING (true);
CREATE POLICY players_insert_own ON players FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY players_update_own ON players FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- GAME ROOMS
CREATE POLICY rooms_select ON game_rooms FOR SELECT TO authenticated
  USING (
    is_public = true
    OR host_id = auth.uid()
    OR is_room_member(id)
  );
CREATE POLICY rooms_insert ON game_rooms FOR INSERT TO authenticated WITH CHECK (auth.uid() = host_id);
CREATE POLICY rooms_update ON game_rooms FOR UPDATE TO authenticated
  USING (auth.uid() = host_id) WITH CHECK (auth.uid() = host_id);

-- ROOM PLAYERS
CREATE POLICY room_players_select ON room_players FOR SELECT TO authenticated
  USING (is_room_member(room_id));
CREATE POLICY room_players_insert ON room_players FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = player_id);
CREATE POLICY room_players_update ON room_players FOR UPDATE TO authenticated
  USING (auth.uid() = player_id) WITH CHECK (auth.uid() = player_id);

-- WORD BANK (read-only)
CREATE POLICY word_bank_select ON word_bank FOR SELECT TO authenticated USING (is_active = true);

-- GAME TURNS (read by room members, written by service_role)
CREATE POLICY game_turns_select ON game_turns FOR SELECT TO authenticated
  USING (is_room_member(room_id));

-- CHAT MESSAGES
CREATE POLICY chat_messages_select ON chat_messages FOR SELECT TO authenticated
  USING (is_room_member(room_id));
CREATE POLICY chat_messages_insert ON chat_messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = player_id);
