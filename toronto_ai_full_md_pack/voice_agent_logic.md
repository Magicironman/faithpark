# Voice Agent Logic

## Intents
- save_parking
- set_timer
- find_car
- get_time_left
- play_news
- what_to_eat
- add_reminder
- spiritual_quote
- change_language

## Routing (pseudo)
if intent == 'find_car': open map
elif intent == 'play_news': fetch→summarize→TTS
elif intent == 'spiritual_quote': select by mood→TTS
...

## Examples (Cantonese)
- 我架車喺邊 → find_car
- 今日有咩新聞 → play_news
- 我好焦慮 → spiritual_quote(anxiety)
- 提我四點移車 → add_reminder
