# Verifiering

Verifierad lokalt 2026-09-17 med Flutter 3.41.5, Dart 3.11.3 och Chrome på macOS.

## Automatiskt

- `flutter analyze`: inga problem.
- `flutter test`: 16 godkända tester.
- `flutter build web --release --no-web-resources-cdn`: lyckat releasebygge, inklusive WASM-kompatibilitetskontroll.
- Responsiva widgettester: alla åtta huvudskärmar vid 360 och 1440 px.
- Formulärvalidering och sparande genom ett riktigt kursformulär.
- SQLite: stäng/öppna databasen, relationsintegritet, opt-in för exempeldata, reset och atomisk validering.
- Statistik, påminnelser, timer/pauser/återstart och exakt en loggpost per avslutat fokuspass.
- Anteckningssökning, källhänvisningar, saknat underlag och lokal AI:s HTTP-kontrakt/felhantering.

## Manuellt i Chrome

- Första start och uttryckligt val av exempeldata.
- Sparande av en egen kurs via webbformuläret, omladdning och bekräftad beständighet.
- Borttagning av den tillfälliga verifieringskursen.
- Frågan ”Hur fungerar ett binärt sökträd?” ger originalutdrag med källa.
- Chrome-inspektion vid 390 px mobilbredd; bokillustrationen tonas ned för läsbarhet.
- Skärmbilder kommer från den körbara Flutter-appen, inte från en designmockup.

## Avgränsningar

- iOS/macOS/Android har genererade plattformsprojekt, men native-byggen har inte körts. Datorn har endast Xcode Command Line Tools och Java 25. Full Xcode/CocoaPods respektive Android SDK/JDK 17 krävs.
- En verklig Ollama-modell har inte installerats eller körts. HTTP-integrationen testas med MockClient.
- Native-systemnotiser, delade grupper, konton, synk och en backend ingår inte.
- Webbläsarimplementationen av SQLite är ett experimentellt tredjepartsberoende; native-lagring och webb-lagring har olika livscykler.
- ID-generering använder ett uttryckligt 31-bitars positivt slumptalsintervall, så att JavaScripts bitoperationer inte gör maxvärdet noll.
- Den medföljande SQLite-WASM-filen matchar den låsta SQLite-versionen 3.5.2. Setup-skriptet korrigerar beroendets äldre standardnedladdning.
