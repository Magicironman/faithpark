# AGENTS.md

## Priorities (MVP)
1. Parking save + timer + notifications
2. Find my car (map)
3. Voice commands (tap-to-speak)
4. News (RSS + Cantonese TTS)
5. Spiritual (daily cards + TTS)

## Tech Rules
- Flutter (clean architecture)
- Services: location, notifications, tts, speech
- Keep offline-first for parking/reminders
- Use APIs for news

## Do Not
- Do not add heavy backend initially
- Do not bundle copyrighted full Bible

## Coding Style
- Feature folders
- Clear service layer
- Simple state management (Provider/riverpod ok)

## Done Criteria
- User can park, set timer, get alert
- User can ask voice commands
- User can play 10-min news
- User can play daily spiritual quote
