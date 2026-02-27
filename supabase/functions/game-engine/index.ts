import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const TURNS_PER_PLAYER = 3;

function getAdminClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

// Levenshtein distance for "close guess" detection
function levenshtein(a: string, b: string): number {
  const matrix: number[][] = [];
  for (let i = 0; i <= b.length; i++) matrix[i] = [i];
  for (let j = 0; j <= a.length; j++) matrix[0][j] = j;

  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }
  return matrix[b.length][a.length];
}

// Generate hint string
function generateHint(word: string, revealPercent: number, seed: string): string {
  const letters = word.split("");
  const concealable: number[] = [];
  letters.forEach((ch, i) => { if (ch !== " ") concealable.push(i); });

  const toReveal = Math.ceil(concealable.length * revealPercent);

  // Deterministic shuffle based on seed
  let hash = 0;
  for (let i = 0; i < seed.length; i++) {
    hash = ((hash << 5) - hash + seed.charCodeAt(i)) | 0;
  }
  const shuffled = [...concealable];
  for (let i = shuffled.length - 1; i > 0; i--) {
    hash = ((hash << 5) - hash + i) | 0;
    const j = Math.abs(hash) % (i + 1);
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  const revealedSet = new Set(shuffled.slice(0, toReveal));

  return letters
    .map((ch, i) => {
      if (ch === " ") return "  ";
      if (revealedSet.has(i)) return ch;
      return "_";
    })
    .join(" ");
}

function generateBlankHint(word: string): string {
  return word.split("").map((c) => (c === " " ? "  " : "_")).join(" ");
}

// ==================== SCORING SYSTEM ====================
// Guesser range: 50–100 (up to 115 with first-guesser bonus)
// Very steep power curve (2.5) to maximize differentiation in tight range
// Drawer gets scaled average of all guesser scores

// Guesser constants
const GUESSER_BASE_SCORE = 50;
const GUESSER_MAX_TIME_BONUS = 50;
const GUESSER_TIME_POWER = 2.5;
const GUESSER_HINT_PENALTY = 0.10;    // 10% reduction per hint
const FIRST_GUESSER_BONUS = 15;

// Drawer constants
const DRAWER_SCALING_FACTOR = 1.1;
const DRAWER_ALL_GUESSED_BONUS = 20;
const DRAWER_MIN_PER_GUESSER = 10;
const SKIP_PENALTY = -30;

// Guesser score: power time decay + first-guesser bonus, reduced by hints
function calculateGuesserScore(
  elapsedSec: number,
  totalSec: number,
  guessRank: number,
  hintsRevealed: number
): number {
  if (totalSec <= 0) return 0;

  const remaining = Math.max(0, totalSec - elapsedSec);
  const timeRatio = Math.min(1, Math.max(0, remaining / totalSec));
  const timeFactor = Math.pow(timeRatio, GUESSER_TIME_POWER);

  const hintMult = Math.max(0, 1.0 - hintsRevealed * GUESSER_HINT_PENALTY);

  let score = (GUESSER_BASE_SCORE + GUESSER_MAX_TIME_BONUS * timeFactor) * hintMult;

  // First guesser gets a flat bonus (added after hint multiplier)
  if (guessRank === 0) {
    score += FIRST_GUESSER_BONUS;
  }

  return Math.max(0, Math.round(score));
}

// Drawer score: scaled average of guesser scores + all-guessed bonus
// Minimum: correctGuesses × 10
function calculateDrawerScore(
  guesserScoresSum: number,
  correctGuesses: number,
  totalGuessers: number
): number {
  if (correctGuesses <= 0 || totalGuessers <= 0) return 0;

  let score = (guesserScoresSum / totalGuessers) * DRAWER_SCALING_FACTOR;

  if (correctGuesses >= totalGuessers) {
    score += DRAWER_ALL_GUESSED_BONUS;
  }

  const minScore = correctGuesses * DRAWER_MIN_PER_GUESSER;
  return Math.max(minScore, Math.round(score));
}

// Broadcast helper
async function broadcastToRoom(
  admin: SupabaseClient,
  roomId: string,
  event: string,
  payload: Record<string, unknown>
) {
  const channel = admin.channel(`game:${roomId}`);
  await channel.subscribe();
  await channel.send({ type: "broadcast", event, payload });
  await admin.removeChannel(channel);
}

// Round winner helper: calculates per-round scores and finds the winner
async function calculateRoundWinner(
  admin: SupabaseClient,
  roomId: string,
  roundNumber: number
): Promise<{ roundWinnerId: string | null; roundScores: Record<string, number> }> {
  // Get all turns in this round
  const { data: roundTurns } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .eq("round_number", roundNumber);

  const turnIds = (roundTurns || []).map((t: any) => t.id);
  const roundScoreMap: Record<string, number> = {};

  // Add drawer scores from game_turns
  for (const t of (roundTurns || [])) {
    roundScoreMap[t.drawer_id] = (roundScoreMap[t.drawer_id] || 0) + (t.drawer_score || 0);
  }

  // Add guesser scores from chat_messages
  if (turnIds.length > 0) {
    const { data: correctGuesses } = await admin
      .from("chat_messages")
      .select("player_id, score_awarded")
      .in("turn_id", turnIds)
      .eq("is_correct", true);

    for (const g of (correctGuesses || [])) {
      roundScoreMap[g.player_id] = (roundScoreMap[g.player_id] || 0) + (g.score_awarded || 0);
    }
  }

  // Find round winner (highest round score)
  let roundWinnerId: string | null = null;
  let maxScore = 0;
  for (const [pid, s] of Object.entries(roundScoreMap)) {
    if (s > maxScore) {
      maxScore = s;
      roundWinnerId = pid;
    }
  }

  return { roundWinnerId, roundScores: roundScoreMap };
}

// Increment rounds_won for a player
async function incrementRoundsWon(
  admin: SupabaseClient,
  roomId: string,
  winnerId: string
): Promise<void> {
  const { data: winner } = await admin
    .from("room_players")
    .select("id, rounds_won")
    .eq("room_id", roomId)
    .eq("player_id", winnerId)
    .is("left_at", null)
    .single();

  if (winner) {
    await admin
      .from("room_players")
      .update({ rounds_won: (winner.rounds_won || 0) + 1 })
      .eq("id", winner.id);
  }
}

// Shared turn progression logic used by both handleEndTurn and handleSkipTurn
async function progressToNextState(
  admin: SupabaseClient,
  roomId: string,
  room: any,
  playersByTurnOrder: any[],
  scoresForDisplay: any[]
) {
  const currentTurnInRound = room.current_turn;
  const totalTurnsInRound = playersByTurnOrder.length * TURNS_PER_PLAYER;
  const currentRound = room.current_round;
  const totalRounds = room.total_rounds;

  if (currentTurnInRound < totalTurnsInRound) {
    // Next turn in same round
    const nextDrawerIdx = currentTurnInRound % playersByTurnOrder.length;
    const nextDrawer = playersByTurnOrder[nextDrawerIdx];

    await new Promise((resolve) => setTimeout(resolve, 4000));
    return await startNextTurn(admin, roomId, room, currentRound, currentTurnInRound + 1, nextDrawer);
  } else if (currentRound < totalRounds) {
    // Round just ended — calculate round winner
    const { roundWinnerId, roundScores } = await calculateRoundWinner(admin, roomId, currentRound);

    if (roundWinnerId) {
      await incrementRoundsWon(admin, roomId, roundWinnerId);
    }

    const roundScoresArray = Object.entries(roundScores).map(([pid, rs]) => ({
      player_id: pid,
      round_score: rs,
    }));

    await broadcastToRoom(admin, roomId, "round_end", {
      scores: scoresForDisplay,
      round_number: currentRound,
      round_scores: roundScoresArray,
      round_winner_id: roundWinnerId,
    });

    await new Promise((resolve) => setTimeout(resolve, 6000));

    const nextDrawer = playersByTurnOrder[0];
    return await startNextTurn(admin, roomId, room, currentRound + 1, 1, nextDrawer);
  } else {
    // Final round just ended — calculate its winner too
    const { roundWinnerId } = await calculateRoundWinner(admin, roomId, currentRound);

    if (roundWinnerId) {
      await incrementRoundsWon(admin, roomId, roundWinnerId);
    }

    // Get final standings sorted by rounds_won DESC, then score DESC (tiebreaker)
    const { data: finalPlayers } = await admin
      .from("room_players")
      .select("*")
      .eq("room_id", roomId)
      .is("left_at", null)
      .order("rounds_won", { ascending: false })
      .order("score", { ascending: false });

    const winner = finalPlayers?.[0];

    const finalScores = (finalPlayers || []).map((p: any) => ({
      player_id: p.player_id,
      display_name: p.display_name,
      score: p.score,
      rounds_won: p.rounds_won,
    }));

    await admin
      .from("game_rooms")
      .update({
        status: "finished",
        current_phase: "game_over",
        game_ended_at: new Date().toISOString(),
      })
      .eq("id", roomId);

    await broadcastToRoom(admin, roomId, "game_over", {
      final_scores: finalScores,
      winner_id: winner?.player_id,
      winner_name: winner?.display_name,
    });

    return { success: true, game_over: true };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { action, room_id, player_id, ...params } = await req.json();
    const admin = getAdminClient();

    let result: Record<string, unknown> = {};

    switch (action) {
      case "start_game":
        result = await handleStartGame(admin, room_id, player_id);
        break;
      case "select_word":
        result = await handleSelectWord(admin, room_id, player_id, params.word);
        break;
      case "submit_guess":
        result = await handleSubmitGuess(admin, room_id, player_id, params.guess);
        break;
      case "request_hint":
        result = await handleRequestHint(admin, room_id);
        break;
      case "end_turn":
        result = await handleEndTurn(admin, room_id);
        break;
      case "skip_turn":
        result = await handleSkipTurn(admin, room_id, player_id);
        break;
      case "play_again":
        result = await handlePlayAgain(admin, room_id, player_id);
        break;
      default:
        result = { error: `Unknown action: ${action}` };
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: result.error ? 400 : 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});

// ==================== ACTION HANDLERS ====================

async function handleStartGame(admin: SupabaseClient, roomId: string, playerId: string) {
  // Validate host
  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room) return { error: "Room not found" };
  if (room.host_id !== playerId) return { error: "Only the host can start the game" };

  // Get active players sorted by turn_order
  const { data: players } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null)
    .order("turn_order", { ascending: true });

  if (!players || players.length < 2) return { error: "Need at least 2 players" };

  // Get first drawer
  const firstDrawer = players[0];

  // Get word choices
  const { data: words } = await admin.rpc("get_random_words", {
    p_difficulty: room.difficulty,
    p_count: room.word_count,
  });

  // Create first game turn
  const { data: turn } = await admin
    .from("game_turns")
    .insert({
      room_id: roomId,
      round_number: 1,
      turn_number: 1,
      drawer_id: firstDrawer.player_id,
      word_choices: words || [],
      guessers_total: players.length - 1,
    })
    .select()
    .single();

  // Update room status
  await admin
    .from("game_rooms")
    .update({
      status: "playing",
      current_phase: "word_selection",
      current_round: 1,
      current_turn: 1,
      current_drawer_id: firstDrawer.player_id,
      game_started_at: new Date().toISOString(),
    })
    .eq("id", roomId);

  // Delay to let clients navigate to game screen and subscribe to channel
  await new Promise((resolve) => setTimeout(resolve, 2000));

  // Broadcast turn start
  await broadcastToRoom(admin, roomId, "turn_start", {
    drawer_id: firstDrawer.player_id,
    drawer_name: firstDrawer.display_name,
    round: 1,
    turn: 1,
    word_length: 0,
    word_choices: words || [],
    turn_id: turn?.id,
  });

  return { success: true, turn_id: turn?.id };
}

async function handleSelectWord(admin: SupabaseClient, roomId: string, playerId: string, word: string) {
  // Get current turn
  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room) return { error: "Room not found" };
  if (room.current_drawer_id !== playerId) return { error: "Not the drawer" };

  const { data: turn } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .is("ended_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (!turn) return { error: "No active turn" };

  // Verify word is in choices
  if (!turn.word_choices.includes(word)) return { error: "Invalid word choice" };

  const endsAt = new Date(Date.now() + room.turn_duration * 1000).toISOString();
  const hint = generateBlankHint(word);

  // Update turn
  await admin
    .from("game_turns")
    .update({
      chosen_word: word,
      word_hint: hint,
      started_at: new Date().toISOString(),
      ends_at: endsAt,
    })
    .eq("id", turn.id);

  // Update room phase
  await admin.from("game_rooms").update({ current_phase: "drawing" }).eq("id", roomId);

  // Broadcast word selected
  await broadcastToRoom(admin, roomId, "word_selected", {
    word_length: word.replace(/ /g, "").length,
    hint,
    ends_at: endsAt,
    word,
  });

  return { success: true, ends_at: endsAt };
}

async function handleSubmitGuess(admin: SupabaseClient, roomId: string, playerId: string, guess: string) {
  if (!guess || guess.trim().length === 0) return { error: "Empty guess" };

  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room || room.current_phase !== "drawing") return { error: "Not in drawing phase" };
  if (room.current_drawer_id === playerId) return { error: "Drawer cannot guess" };

  // Check if already guessed
  const { data: player } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .eq("player_id", playerId)
    .is("left_at", null)
    .single();

  if (!player) return { error: "Not in room" };
  if (player.has_guessed) return { error: "Already guessed correctly" };

  // Get current turn for the word
  const { data: turn } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .is("ended_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (!turn || !turn.chosen_word) return { error: "No active turn" };

  const normalizedGuess = guess.trim().toLowerCase();
  const normalizedWord = turn.chosen_word.trim().toLowerCase();

  // Check for correct guess
  if (normalizedGuess === normalizedWord) {
    // Guard against null/invalid started_at to prevent NaN scores
    if (!turn.started_at) return { error: "Turn timer not started" };
    const startedAtMs = new Date(turn.started_at).getTime();
    if (isNaN(startedAtMs)) return { error: "Invalid turn start time" };
    const elapsedSec = Math.max(0, (Date.now() - startedAtMs) / 1000);

    // Rank = how many have already guessed before this player
    const guessRank = turn.correct_guesses || 0;
    const hintsRevealed: number = (turn.turn_data?.hints_given as number) || 0;

    const score = calculateGuesserScore(elapsedSec, room.turn_duration, guessRank, hintsRevealed);

    // Update player
    await admin
      .from("room_players")
      .update({
        has_guessed: true,
        score: player.score + score,
        correct_guesses: player.correct_guesses + 1,
      })
      .eq("id", player.id);

    // Update turn: increment correct_guesses (drawer score computed at turn end)
    const newCorrectCount = turn.correct_guesses + 1;
    await admin
      .from("game_turns")
      .update({ correct_guesses: newCorrectCount })
      .eq("id", turn.id);

    // Persist correct guess
    await admin.from("chat_messages").insert({
      room_id: roomId,
      player_id: playerId,
      turn_id: turn.id,
      message_type: "correct",
      content: guess,
      is_correct: true,
      score_awarded: score,
    });

    // Broadcast correct guess
    await broadcastToRoom(admin, roomId, "correct_guess", {
      player_id: playerId,
      display_name: player.display_name,
      score,
    });

    // Check if all guessers have guessed
    if (newCorrectCount >= turn.guessers_total) {
      await handleEndTurn(admin, roomId);
    }

    return { success: true, correct: true, score };
  }

  // Check for close guess
  const dist = levenshtein(normalizedGuess, normalizedWord);
  if (dist <= 1 && dist > 0) {
    await broadcastToRoom(admin, roomId, "close_guess", {
      player_id: playerId,
      display_name: player.display_name,
    });
    return { success: true, close: true };
  }

  // Wrong guess - broadcast to chat
  await broadcastToRoom(admin, roomId, "wrong_guess", {
    player_id: playerId,
    display_name: player.display_name,
    text: guess,
  });

  return { success: true, correct: false };
}

async function handleRequestHint(admin: SupabaseClient, roomId: string) {
  const { data: turn } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .is("ended_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (!turn || !turn.chosen_word || !turn.started_at || !turn.ends_at) {
    return { error: "No active turn" };
  }

  const totalMs = new Date(turn.ends_at).getTime() - new Date(turn.started_at).getTime();
  const elapsedMs = Date.now() - new Date(turn.started_at).getTime();
  const ratio = elapsedMs / totalMs;

  let revealPercent = 0;
  if (ratio >= 0.75) {
    revealPercent = 0.5;
  } else if (ratio >= 0.5) {
    revealPercent = 0.25;
  } else {
    return { success: true, message: "Too early for hints" };
  }

  const hint = generateHint(turn.chosen_word, revealPercent, turn.id);
  const newHintsGiven = revealPercent <= 0.25 ? 1 : 2;

  // Update turn hint and persist hint count for scoring
  await admin.from("game_turns").update({
    word_hint: hint,
    turn_data: { ...(turn.turn_data || {}), hints_given: newHintsGiven },
  }).eq("id", turn.id);

  // Broadcast
  await broadcastToRoom(admin, roomId, "hint_update", { hint });

  return { success: true, hint };
}

async function handleEndTurn(admin: SupabaseClient, roomId: string) {
  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room) return { error: "Room not found" };

  const { data: turn } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .is("ended_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (!turn) return { error: "No active turn" };

  // Calculate drawer score from guesser scores (average × engagement multiplier)
  let drawerScore = 0;
  if (turn.correct_guesses > 0) {
    const { data: correctGuesses } = await admin
      .from("chat_messages")
      .select("score_awarded")
      .eq("turn_id", turn.id)
      .eq("is_correct", true);

    const guesserScoresSum = (correctGuesses || []).reduce(
      (sum: number, g: any) => sum + (g.score_awarded || 0), 0
    );
    drawerScore = calculateDrawerScore(guesserScoresSum, turn.correct_guesses, turn.guessers_total);
  }

  // Atomically end the turn (only if not already ended) to prevent race conditions
  const { data: updatedTurn } = await admin
    .from("game_turns")
    .update({
      ended_at: new Date().toISOString(),
      drawer_score: drawerScore,
    })
    .eq("id", turn.id)
    .is("ended_at", null)
    .select()
    .maybeSingle();

  if (!updatedTurn) {
    // Another call already ended this turn
    return { success: true, already_ended: true };
  }

  // Update drawer's score and drawings_done
  const { data: drawer } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .eq("player_id", turn.drawer_id)
    .is("left_at", null)
    .single();

  if (drawer) {
    await admin
      .from("room_players")
      .update({
        score: drawer.score + drawerScore,
        drawings_done: drawer.drawings_done + 1,
      })
      .eq("id", drawer.id);
  }

  // Get players sorted by score for display
  const { data: playersByScore } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null)
    .order("score", { ascending: false });

  // Get players sorted by turn_order for rotation
  const { data: playersByTurnOrder } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null)
    .order("turn_order", { ascending: true });

  const scoresForDisplay = (playersByScore || []).map((p: any) => ({
    player_id: p.player_id,
    display_name: p.display_name,
    score: p.score,
  }));

  // Broadcast turn end
  await broadcastToRoom(admin, roomId, "turn_end", {
    word: turn.chosen_word,
    drawer_score: drawerScore,
    scores: scoresForDisplay,
  });

  // Reset has_guessed for all players
  await admin
    .from("room_players")
    .update({ has_guessed: false })
    .eq("room_id", roomId)
    .is("left_at", null);

  // Progress to next turn/round/game-over
  return await progressToNextState(admin, roomId, room, playersByTurnOrder || [], scoresForDisplay);
}

async function startNextTurn(
  admin: SupabaseClient,
  roomId: string,
  room: any,
  roundNumber: number,
  turnNumber: number,
  drawer: any
) {
  const { data: words } = await admin.rpc("get_random_words", {
    p_difficulty: room.difficulty,
    p_count: room.word_count,
  });

  const { data: players } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null);

  const { data: turn } = await admin
    .from("game_turns")
    .insert({
      room_id: roomId,
      round_number: roundNumber,
      turn_number: turnNumber,
      drawer_id: drawer.player_id,
      word_choices: words || [],
      guessers_total: (players?.length || 1) - 1,
    })
    .select()
    .single();

  await admin
    .from("game_rooms")
    .update({
      current_phase: "word_selection",
      current_round: roundNumber,
      current_turn: turnNumber,
      current_drawer_id: drawer.player_id,
    })
    .eq("id", roomId);

  // Short delay to let clients process previous phase transition
  await new Promise((resolve) => setTimeout(resolve, 1500));

  await broadcastToRoom(admin, roomId, "turn_start", {
    drawer_id: drawer.player_id,
    drawer_name: drawer.display_name,
    round: roundNumber,
    turn: turnNumber,
    word_length: 0,
    word_choices: words || [],
    turn_id: turn?.id,
  });

  return { success: true, turn_id: turn?.id };
}

async function handleSkipTurn(admin: SupabaseClient, roomId: string, playerId: string) {
  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room) return { error: "Room not found" };
  if (room.current_drawer_id !== playerId) return { error: "Not the drawer" };

  // Get current turn
  const { data: turn } = await admin
    .from("game_turns")
    .select("*")
    .eq("room_id", roomId)
    .is("ended_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (!turn) return { error: "No active turn" };

  const penalty = SKIP_PENALTY;

  // End the turn with penalty
  await admin
    .from("game_turns")
    .update({
      ended_at: new Date().toISOString(),
      drawer_score: penalty,
      chosen_word: turn.chosen_word || "(skipped)",
    })
    .eq("id", turn.id);

  // Deduct score from drawer
  const { data: drawer } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .eq("player_id", playerId)
    .is("left_at", null)
    .single();

  if (drawer) {
    await admin
      .from("room_players")
      .update({ score: Math.max(0, drawer.score + penalty) })
      .eq("id", drawer.id);
  }

  // Get players sorted by score for display
  const { data: playersByScore } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null)
    .order("score", { ascending: false });

  // Get players sorted by turn_order for rotation
  const { data: playersByTurnOrder } = await admin
    .from("room_players")
    .select("*")
    .eq("room_id", roomId)
    .is("left_at", null)
    .order("turn_order", { ascending: true });

  const scoresForDisplay = (playersByScore || []).map((p: any) => ({
    player_id: p.player_id,
    display_name: p.display_name,
    score: p.score,
  }));

  // Broadcast turn end with skipped info
  await broadcastToRoom(admin, roomId, "turn_end", {
    word: "(skipped)",
    drawer_score: penalty,
    scores: scoresForDisplay,
  });

  // Reset has_guessed for all players
  await admin
    .from("room_players")
    .update({ has_guessed: false })
    .eq("room_id", roomId)
    .is("left_at", null);

  // Progress to next turn/round/game-over
  return await progressToNextState(admin, roomId, room, playersByTurnOrder || [], scoresForDisplay);
}

async function handlePlayAgain(admin: SupabaseClient, roomId: string, playerId: string) {
  const { data: room } = await admin.from("game_rooms").select("*").eq("id", roomId).single();
  if (!room) return { error: "Room not found" };
  if (room.host_id !== playerId) return { error: "Only the host can restart" };

  await admin
    .from("game_rooms")
    .update({
      status: "waiting",
      current_phase: null,
      current_round: 0,
      current_turn: 0,
      current_drawer_id: null,
      game_started_at: null,
      game_ended_at: null,
    })
    .eq("id", roomId);

  await admin
    .from("room_players")
    .update({ score: 0, has_guessed: false, is_ready: false, correct_guesses: 0, drawings_done: 0, rounds_won: 0 })
    .eq("room_id", roomId)
    .is("left_at", null);

  await broadcastToRoom(admin, roomId, "game_reset", {});

  return { success: true };
}
