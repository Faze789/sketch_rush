-- ============================================================================
-- Migration 009: Triggers & Utility Functions
-- ============================================================================

-- 1. Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_players_updated_at
  BEFORE UPDATE ON players FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_game_rooms_updated_at
  BEFORE UPDATE ON game_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. Auto-create player profile on auth signup
CREATE OR REPLACE FUNCTION handle_new_player()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.players (id, display_name)
  VALUES (
    NEW.id,
    coalesce(NEW.raw_user_meta_data->>'display_name', 'Player_' || substr(NEW.id::text, 1, 6))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_player();

-- 3. Generate unique 6-char room code
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TRIGGER AS $$
DECLARE
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code text;
  i integer;
  attempts integer := 0;
BEGIN
  IF NEW.room_code IS NULL OR NEW.room_code = '' THEN
    LOOP
      code := '';
      FOR i IN 1..6 LOOP
        code := code || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
      END LOOP;
      IF NOT EXISTS (SELECT 1 FROM game_rooms WHERE room_code = code) THEN
        NEW.room_code := code;
        EXIT;
      END IF;
      attempts := attempts + 1;
      IF attempts > 100 THEN
        RAISE EXCEPTION 'Could not generate unique room code';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_room_code
  BEFORE INSERT ON game_rooms FOR EACH ROW EXECUTE FUNCTION generate_room_code();

-- 4. Auto-assign turn_order on player join
CREATE OR REPLACE FUNCTION assign_turn_order()
RETURNS TRIGGER AS $$
BEGIN
  NEW.turn_order := (
    SELECT coalesce(max(turn_order), 0) + 1
    FROM room_players WHERE room_id = NEW.room_id AND left_at IS NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_turn_order
  BEFORE INSERT ON room_players FOR EACH ROW EXECUTE FUNCTION assign_turn_order();

-- 5. Handle player leave (abandon empty rooms, transfer host)
CREATE OR REPLACE FUNCTION handle_player_leave()
RETURNS TRIGGER AS $$
DECLARE
  active_count integer;
  room_host uuid;
BEGIN
  IF OLD.left_at IS NULL AND NEW.left_at IS NOT NULL THEN
    SELECT count(*) INTO active_count
    FROM room_players
    WHERE room_id = NEW.room_id AND left_at IS NULL AND player_id != NEW.player_id;

    IF active_count = 0 THEN
      UPDATE game_rooms SET status = 'abandoned' WHERE id = NEW.room_id;
    ELSE
      SELECT host_id INTO room_host FROM game_rooms WHERE id = NEW.room_id;
      IF room_host = NEW.player_id THEN
        UPDATE game_rooms SET host_id = (
          SELECT player_id FROM room_players
          WHERE room_id = NEW.room_id AND left_at IS NULL AND player_id != NEW.player_id
          ORDER BY turn_order ASC LIMIT 1
        ) WHERE id = NEW.room_id;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_handle_player_leave
  AFTER UPDATE OF left_at ON room_players FOR EACH ROW EXECUTE FUNCTION handle_player_leave();
