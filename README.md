

# Sticks Board Game: AI Opponent & LLM Evaluation

A Flutter implementation of the Sticks board game featuring multiple AI opponent strategies and an OpenAI powered LLM evaluation mode.

The project was developed to explore different approaches to automated decision-making in a rule-based board game. It supports human gameplay, three CPU difficulty levels, and experiments in which an LLM competes against the built-in AI strategies.

## Features

- Play the Sticks board game through a Flutter graphical interface
- Human vs. Human gameplay
- Human vs. AI gameplay
- Three AI difficulty levels:
  - **Easy, Random:** selects a legal move at random
  - **Medium, Greedy:** prioritizes immediate progress, captures, and finishing moves
  - **Hard, Heuristic:** evaluates captures, stacking, finishing, and overall team progress
- LLM-controlled player using the OpenAI API
- Automated LLM vs. AI experiments
- Experiment tracking for wins, losses, draws, actions, fallback moves, and runtime
- Automated testing for game rules, AI strategies, integrations, configuration, and UI behavior

## Technologies

- **Dart**
- **Flutter**
- **OpenAI API**
- **HTTP**
- **VS Code**
- **Git / GitHub**

## Project Structure

```text
lib/
├── ai/
│   ├── ai_strategy.dart
│   ├── ai_strategy_factory.dart
│   ├── ai_turn_controller.dart
│   ├── greedy_medium_strategy.dart
│   ├── heuristic_hard_strategy.dart
│   ├── llm_strategy.dart
│   └── random_easy_strategy.dart
│
├── experiments/
│   ├── experiment_result.dart
│   └── llm_vs_ai_runner.dart
│
├── game/
│   ├── board.dart
│   ├── game.dart
│   ├── game_engine.dart
│   ├── game_state.dart
│   ├── piece.dart
│   ├── player.dart
│   └── team.dart
│
├── llm/
│   ├── llm_client.dart
│   ├── prompt_builder.dart
│   └── response_parser.dart
│
├── models/
├── widgets/
└── main.dart
```

The project separates the game engine, AI strategies, LLM integration, experiment system, and Flutter interface into independent components.

## AI Difficulty System

The CPU opponent uses three strategy implementations.

### Easy, Random

The Random strategy selects one available legal move at random. This provides a baseline opponent with no move optimization.

### Medium, Greedy

The Greedy strategy prioritizes immediate benefits such as forward progress, captures, and finishing moves.

### Hard, Heuristic

The Heuristic strategy evaluates additional game-state information, including captures, stacking, finishing opportunities, and team progress.

A strategy factory selects the appropriate implementation based on the chosen difficulty level.

## LLM Integration

The project includes an LLM-controlled player using the OpenAI API.

During an LLM turn, the application:

1. Determines the current game state and available legal moves.
2. Converts the relevant game information into a structured prompt.
3. Sends the prompt to the OpenAI API.
4. Parses the model's selected move.
5. Validates the response against the available legal moves.
6. Executes the move through the game engine.

The LLM is instructed to select only from the legal move list and prioritize finishing pieces, captures, useful shortcuts, and forward progress.

The API key is not stored directly in the source code.

## LLM vs. AI Experiments

The application can run automated matches between the LLM player and any of the three CPU difficulty levels.

The experiment runner records:

- LLM wins
- AI wins
- Draws
- Total actions
- LLM fallback moves
- Experiment runtime

This provides a repeatable way to evaluate the LLM against progressively different decision strategies.

## Testing

The project contains **180+ automated test cases** covering areas including:

- Board movement
- Team and game rules
- Random AI strategy
- Greedy AI strategy
- Heuristic AI strategy
- AI strategy selection
- AI turn control
- AI integration
- Game-state snapshots
- Match configuration
- Human vs. AI setup
- Main menu behavior

Tests are located in the `test/` directory and can be executed with:

```bash
flutter test
```

## Running the Project

### Requirements

- Flutter SDK
- Dart SDK
- A supported Flutter development environment
- OpenAI API key for LLM experiment mode

### 1. Clone the repository

```bash
git clone YOUR_REPOSITORY_URL
cd Sticks-Board-Game-AI
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run without LLM mode

```bash
flutter run
```

### 4. Run with OpenAI API access

The API key is supplied at runtime rather than stored in the repository.

```bash
flutter run --dart-define=OPENAI_API_KEY=YOUR_API_KEY
```

## Development Evidence

The repository also includes selected project documentation in `project_evidence/`, including:

- AI architecture documentation
- Prompt iterations
- Game rules and scope
- AI invariants
- Test results

These materials document the development and evaluation process used while building the project.

## Author

**Alonzo Herrera**  
B.S. Artificial Intelligence Student  
University of Texas at El Paso

[LinkedIn](https://www.linkedin.com/in/alonzoherrera/) | [GitHub](https://github.com/AlonzoHerrera)



