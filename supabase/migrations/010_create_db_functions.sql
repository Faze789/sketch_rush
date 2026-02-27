-- ============================================================================
-- Migration 010: Database Functions (RPC)
-- ============================================================================

-- 1. Join a room by code
CREATE OR REPLACE FUNCTION join_room(p_room_code text, p_player_id uuid)
RETURNS jsonb AS $$
DECLARE
  v_room game_rooms%ROWTYPE;
  v_player players%ROWTYPE;
  v_current_count integer;
BEGIN
  SELECT * INTO v_room FROM game_rooms WHERE room_code = upper(p_room_code);
  IF v_room.id IS NULL THEN
    RETURN jsonb_build_object('error', 'Room not found');
  END IF;

  IF v_room.status NOT IN ('waiting', 'playing') THEN
    RETURN jsonb_build_object('error', 'Room is not accepting players');
  END IF;

  IF EXISTS (
    SELECT 1 FROM room_players WHERE room_id = v_room.id AND player_id = p_player_id AND left_at IS NULL
  ) THEN
    RETURN jsonb_build_object('success', true, 'room_id', v_room.id, 'message', 'Already in room');
  END IF;

  SELECT count(*) INTO v_current_count FROM room_players WHERE room_id = v_room.id AND left_at IS NULL;
  IF v_current_count >= v_room.max_players THEN
    RETURN jsonb_build_object('error', 'Room is full');
  END IF;

  SELECT * INTO v_player FROM players WHERE id = p_player_id;

  INSERT INTO room_players (room_id, player_id, display_name, avatar_index, avatar_color)
  VALUES (v_room.id, p_player_id, v_player.display_name, v_player.avatar_index, v_player.avatar_color);

  RETURN jsonb_build_object('success', true, 'room_id', v_room.id, 'room_code', v_room.room_code, 'room_name', v_room.room_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Leave a room
CREATE OR REPLACE FUNCTION leave_room(p_room_id uuid, p_player_id uuid)
RETURNS jsonb AS $$
BEGIN
  UPDATE room_players SET left_at = now()
  WHERE room_id = p_room_id AND player_id = p_player_id AND left_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Not in room');
  END IF;
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Get random words for drawer selection
CREATE OR REPLACE FUNCTION get_random_words(
  p_difficulty word_difficulty DEFAULT 'medium',
  p_count integer DEFAULT 3,
  p_language text DEFAULT 'en',
  p_exclude text[] DEFAULT '{}'
)
RETURNS text[] AS $$
DECLARE
  words text[];
BEGIN
  SELECT array_agg(w.word) INTO words FROM (
    SELECT word FROM word_bank
    WHERE difficulty = p_difficulty AND language = p_language AND is_active = true AND word != ALL(p_exclude)
    ORDER BY random() LIMIT p_count
  ) w;
  RETURN coalesce(words, '{}');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 4. List public rooms with player counts
CREATE OR REPLACE FUNCTION list_public_rooms(p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
RETURNS TABLE (
  id uuid, room_code text, room_name text, host_name text, max_players integer,
  current_players bigint, total_rounds integer, difficulty word_difficulty,
  status room_status, created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT gr.id, gr.room_code, gr.room_name, p.display_name AS host_name, gr.max_players,
    (SELECT count(*) FROM room_players rp WHERE rp.room_id = gr.id AND rp.left_at IS NULL) AS current_players,
    gr.total_rounds, gr.difficulty, gr.status, gr.created_at
  FROM game_rooms gr JOIN players p ON p.id = gr.host_id
  WHERE gr.is_public = true AND gr.status = 'waiting'
  ORDER BY gr.created_at DESC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5. Cleanup stale rooms
CREATE OR REPLACE FUNCTION cleanup_stale_rooms()
RETURNS integer AS $$
DECLARE cleaned integer;
BEGIN
  UPDATE game_rooms SET status = 'abandoned'
  WHERE status = 'waiting' AND updated_at < now() - interval '1 hour';
  GET DIAGNOSTICS cleaned = ROW_COUNT;

  DELETE FROM game_rooms WHERE status IN ('finished', 'abandoned') AND created_at < now() - interval '7 days';
  RETURN cleaned;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
