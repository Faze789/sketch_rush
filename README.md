# Sketch Rush

A real-time multiplayer drawing and guessing game built with **Flutter** and **Supabase**.

Players join rooms, take turns drawing a secret word on a shared canvas, and race to guess what's being drawn — Pictionary-style, right from your phone.

## Features

- **Real-time multiplayer** — powered by Supabase Realtime for instant sync across players
- **Drawing canvas** — smooth freehand strokes with color picker and stroke tools
- **Live chat & guessing** — type your guesses in real-time; correct answers are detected automatically
- **Room system** — create or join game rooms with lobby management
- **Turn-based gameplay** — automatic turn rotation with timers, word selection, and hint reveals
- **Scoring & leaderboard** — points for correct guesses and game-over summary screen
- **Anonymous play** — jump in without creating an account

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| State Management | GetX |
| Backend & Realtime | Supabase (Auth, Database, Realtime, Edge Functions) |
| Drawing Engine | perfect_freehand |

## Getting Started

### Prerequisites

- Flutter SDK (3.x+)
- A Supabase project with Realtime enabled

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Faze789/sketch_rush.git
   cd sketch_rush
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure your Supabase credentials (URL and anon key) in the project.

4. Run the app:
   ```bash
   flutter run
   ```

## How to Play

1. Open the app and enter a display name
2. Create a new room or join an existing one from the lobby
3. Once enough players join, the game begins
4. The drawer picks a word and sketches it on the canvas
5. Other players type guesses in the chat — first correct guess scores the most points
6. After all rounds, the player with the highest score wins!
