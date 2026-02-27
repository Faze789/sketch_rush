-- ============================================================================
-- Migration 007: Chat Messages
-- ============================================================================

CREATE TABLE chat_messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         uuid NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  player_id       uuid REFERENCES players(id),
  turn_id         uuid REFERENCES game_turns(id),
  message_type    message_type NOT NULL DEFAULT 'guess',
  content         text NOT NULL,
  is_correct      boolean DEFAULT false,
  score_awarded   integer DEFAULT 0,
  created_at      timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_chat_messages_room ON chat_messages (room_id, created_at);
CREATE INDEX idx_chat_messages_correct ON chat_messages (turn_id, is_correct) WHERE is_correct = true;

COMMENT ON TABLE chat_messages IS 'Persisted chat/guess history per room';
