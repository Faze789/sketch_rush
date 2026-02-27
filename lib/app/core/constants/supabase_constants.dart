class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://swumprctmlvhmfrcgghw.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3dW1wcmN0bWx2aG1mcmNnZ2h3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NTQ3MDIsImV4cCI6MjA4NzQzMDcwMn0.vneibFbb9AvNd19lDT7-GL7-0Z_ExXMB4BGFtqIusT8',
  );

  // Realtime channel prefixes
  static String roomChannel(String roomId) => 'room:$roomId';
  static String gameChannel(String roomId) => 'game:$roomId';

  // Broadcast event names
  static const String eventStrokeData = 'stroke_data';
  static const String eventStrokeUndo = 'stroke_undo';
  static const String eventStrokeClear = 'stroke_clear';
  static const String eventCanvasRequest = 'canvas_request';
  static const String eventCanvasSnapshot = 'canvas_snapshot';
  static const String eventTurnStart = 'turn_start';
  static const String eventWordSelected = 'word_selected';
  static const String eventHintUpdate = 'hint_update';
  static const String eventCorrectGuess = 'correct_guess';
  static const String eventCloseGuess = 'close_guess';
  static const String eventWrongGuess = 'wrong_guess';
  static const String eventTurnEnd = 'turn_end';
  static const String eventRoundEnd = 'round_end';
  static const String eventGameOver = 'game_over';
  static const String eventGameReset = 'game_reset';
  static const String eventChatMessage = 'chat_message';
  static const String eventTimeSync = 'time_sync';
}
