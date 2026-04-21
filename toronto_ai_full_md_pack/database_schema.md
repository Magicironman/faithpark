# Database Schema (Isar)

## ParkingSession
- id, lat, lng, address
- startTime, endTime, durationMinutes
- note, photoPath
- isActive

## TaskReminder
- id, title, dueTime, repeatType
- voiceEnabled, vibrationEnabled

## UserSettings
- uiLanguage, speechLanguage
- defaultParkingMinutes
- newsDurationMinutes
- dailyQuoteTime
- autoplayVoice

## CachedNews
- id, title, summary, source, category, timestamp

## Verse (selected)
- id, reference
- textZhHant, textEn
- category (peace, anxiety, wisdom, etc.)

## FavoriteVerse
- id, verseId, savedAt, note
