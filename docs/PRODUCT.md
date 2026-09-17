# Produktbeslut: StudentHub v1

## Målgrupp och problem

Studenter som vill samla tentor, deadlines och dagliga studievanor utan att behöva organisera ett stort produktivitetsverktyg. Den första användaren behöver få värde på några minuter, utan konton eller integrationer.

**Viktigaste användarresan:** lägg till en kurs → planera nästa konkreta studiepass → genomför ett fokuspass → se framsteget.

## Beslut

| Beslut | Motivering | Kostnad / avvägning |
|---|---|---|
| Manuell inmatning först | Produkten fungerar oberoende av tillgång till skolans API:er | Användaren håller själv uppgifterna uppdaterade |
| Lokal SQLite | Låg tröskel, ingen driftkostnad och begripligt dataägande | Ingen synk eller delning; användaren ansvarar för enhetens data |
| Flutter med responsivt gränssnitt | En kodbas för mobil och dator | Native-byggen behöver plattformarnas SDK:er |
| Valfri demo | Gör produkten lätt att bedöma utan att blanda in riktiga studentuppgifter | Exempel måste märkas och kunna rensas |
| Studiegrupper som egen planering | Testar värdet av gruppsamordning innan konton och chatt byggs | Medlemmar får inte automatiskt uppdateringar |
| Lokala källutdrag före AI | Ger omedelbar nytta och synlig koppling till användarens text | Nyckelordssökning förstår inte alla synonymer |
| Valfri Ollama | Riktig generering kan provas utan API-nycklar i klienten | Kräver lokal modell och tillräcklig hårdvara |
| In-app-påminnelser | Tydlig första funktion utan plattformsspecifik bakgrundshantering | Ersätter inte systemkalenderns larm |

## Acceptans för v1

- Användaren kan skapa, uppdatera, hitta, slutföra och ta bort sin studieplanering.
- Egna uppgifter finns kvar efter omstart.
- Tomma och felaktiga formulär ger begriplig återkoppling.
- Exempeldata skapas bara efter uttryckligt val.
- Fokuspass dubbelregistreras inte när appen öppnas igen.
- Statistik bygger på sparade uppgifter; inga påhittade framsteg.
- Anteckningshjälp visar vilka utdrag ett svar bygger på och när underlag saknas.
- Mobil och dator har användbara navigerings- och formulärflöden.

## Nästa steg

1. **Validera användarbehovet.** Låt fem studenter planera en vecka och dokumentera var de fastnar. Mät tid till första kurs och första planerade pass genom användartester, inte dold telemetri.
2. **Skydda arbetet.** Export/import av säkerhetskopior, återställning av raderade poster, återkommande aktiviteter och mer tillgänglighetstestning med skärmläsare.
3. **Påminnelser som når fram.** Native-notiser med explicita tillstånd, tidszoner, sommartid och testad bakgrundshantering.
4. **Backend vid visat behov.** Python FastAPI + PostgreSQL/Supabase, autentisering, per-användaråtkomst, synk och konflikthantering. Därefter delade studiegrupper.
5. **Bättre frågehjälp.** Filimport, semantisk sökning, källförankrad generering och kvalitetstester för svenska kursanteckningar.
6. **Skolkopplingar.** Utred officiella API:er och tillstånd. Behåll manuell inmatning som robust alternativ.

## Förslag på framtida REST-gränssnitt

`GET/POST /courses`, `PATCH/DELETE /courses/{id}`, motsvarande resurser för `entries`, `notes`, `groups` och `focus-sessions`. `POST /notes/ask` tar fråga och kursfilter. Servern ska härleda ägaren från sessionen, aldrig lita på ett klientskickat användar-id. Detta är en plan, ingen befintlig backend.
