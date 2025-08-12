# Claude Instructions for Flutter Tetris Game

This is a Flutter-based Tetris game project. When working on this codebase, please follow these guidelines:

## Project Structure
- This is a Flutter application written in Dart
- Main game logic and UI components are likely in the `lib/` directory
- Game features include:
  - Next piece preview
  - Game pause/restart functionality
  - Game Over detection and display
  - Scoring system with combo logic

## Development Commands
When making changes to this project, please run these commands to ensure code quality:

```bash
# Format code
flutter format .

# Analyze code for issues
flutter analyze

# Run tests (if available)
flutter test

# Build the app
flutter build apk
```

## Recent Features (based on git history)
- Next piece display functionality
- Game pause/restart mechanics
- Game Over detection and alerts
- Scoring system with combo mechanics
- Various bug fixes and improvements

## Guidelines
- Follow Flutter/Dart conventions and best practices
- Maintain existing code style and patterns
- Test changes when possible before committing
- Focus on game mechanics, UI, and user experience improvements
- When adding new features or refactoring code, maintain existing functionality as the top priority

## Testing
Before making commits, ensure:
1. Code compiles without errors (`flutter analyze`)
2. Code is properly formatted (`flutter format .`)
3. App builds successfully (`flutter build apk`)
4. Game functionality works as expected