// lib/ia/cles_api.dart
//
// La clé Groq (palier gratuit, console.groq.com — celle de Studio et Net
// Worth) N'EST PAS dans le code : elle vient de la construction,
//   flutter build apk --release --dart-define-from-file=cles.json
// où `cles.json` (hors du dépôt, `.gitignore`) contient
//   {"GROQ_CLE": "gsk_…"}
// Sans elle, l'assistant le dit (`ErreurIa.sansCle`) et le reste de l'app
// marche comme avant.

const String kCleGroq = String.fromEnvironment('GROQ_CLE');
