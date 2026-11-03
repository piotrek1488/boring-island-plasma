# Analiza gałęzi dev i decyzje portu

Analizowany commit: `1f965d8b5ec950d3e407cbc63695ba8d90a03ac1`.
Repozytorium pobrano bezpośrednio z gałęzi `dev` 2026-11-03. Podgląd strony GitHub
w wyszukiwarce był przestarzały, dlatego podstawą analizy jest kod tego commita,
a nie lista roadmap ze starego README. W pobranym drzewie LICENSE zawiera GPL v3.

## Architektura oryginału

Oryginał używa SwiftUI, Combine i Defaults. `BoringViewModel` zarządza stanem
zamknięcia/otwarcia, rozmiarem i zależnym od monitora chowaniem w pełnym ekranie.
`NotchWindowManager` i `NotchSpaceManager` odpowiadają za okna i przestrzenie macOS.
`NotchShape` rysuje kształt z osobnymi promieniami u góry i na dole.
`NotchHomeView` składa okładkę, informacje i konfigurowalne sterowanie muzyką.

`MusicManager` utrzymuje metadane, czas, tempo, głośność i wybrany kontroler
multimediów oraz obsługuje błędy i zmianę kontrolera. `BatteryActivityManager`
korzysta z IOKit; `CalendarManager` z dostępu do kalendarza i przypomnień Apple.
Półka ma odrębne modele i usługi drop/share/persistence/temporary storage;
`ShelfPersistenceService` zapisuje obiekty ShelfItem w JSON, odtwarza prawidłowe
rekordy nawet przy częściowo uszkodzonych danych. `NotchUIEvent` i komponenty
LiveActivities rozdzielają prezentację zdarzeń od ich źródeł.

## Mapowanie

| Oryginał | Implementacja Linux 0.2 | Stan |
|---|---|---|
| NotchShape, BoringViewModel | IslandSurface, CompactView, main.qml | Dwa kształty, hover/click, opóźnienie |
| NSWindow / Spaces | PlasmoidItem i host Plasma | Panel + popup albo widżet pulpitu |
| MusicManager / kontrolery Apple | SystemBackend / Mpris2Model | Transport, metadane, seek, głośność |
| IOKit / BatteryActivityManager | BatteryControlModel z Plasma | Procent, zasilanie, brak baterii |
| ShelfPersistenceService | KConfig + Shelf.js | Trwałe lokalne skróty, deduplikacja, limit |
| ShelfDropService / QuickLook | DropArea + domyślna aplikacja | Drop, otwieranie, drag-out; bez QuickLook |
| Kalendarz/EventKit | Plasma Calendar + pimevents/Akonadi | Agenda dnia, wspólny wybór kalendarzy z zegarem Plasma |
| AirDrop / Apple sharing | KDE Connect / ShareDbusInterface | Wybór urządzenia, zlecenie transferu, obsługa błędów D-Bus |
| Kamera / audio capture / OSD / notifications | — | Poza zakresem tej wersji |

## Dlaczego QML

SwiftUI/AppKit nie są warstwą interfejsu KDE. Implementacja została napisana
ponownie w QML/JavaScript, korzysta z usług już dostarczanych przez Plasma i nie
uruchamia poleceń powłoki na podstawie metadanych ani nazw plików. MPRIS zapewnia
jedną ścieżkę integracji dla odtwarzaczy linuksowych. KConfig utrzymuje ustawienia
widżetu bez własnego serwera. Użycie prywatnych modułów KDE ogranicza przenośność
między wersjami, dlatego minimum ustalono na zweryfikowaną serię 6.6.

Na Waylandzie zwykły plasmoid nie powinien sam arbitralnie pozycjonować okna ani
przechwytywać globalnych wejść. Pozycjonowanie i wielomonitorowość są zadaniem
panelu Plasma. Rozwinięcie panelowe jest popupem, nie płynnym przekształceniem
jednego niezależnego okna jak w oryginale. Desktop ma rezerwowany obszar 440×286;
zamknięta kapsuła zajmuje jego górną część. Podobieństwo funkcjonalne nie oznacza
pełnej zgodności animacji, geometrii czy wszystkich integracji upstream.

## Źródła

- [BoringViewModel.swift](https://github.com/TheBoredTeam/boring.notch/blob/1f965d8b5ec950d3e407cbc63695ba8d90a03ac1/boringNotch/models/BoringViewModel.swift)
- [NotchHomeView.swift](https://github.com/TheBoredTeam/boring.notch/blob/1f965d8b5ec950d3e407cbc63695ba8d90a03ac1/boringNotch/components/Notch/NotchHomeView.swift)
- [MusicManager.swift](https://github.com/TheBoredTeam/boring.notch/blob/1f965d8b5ec950d3e407cbc63695ba8d90a03ac1/boringNotch/managers/MusicManager.swift)
- [ShelfPersistenceService.swift](https://github.com/TheBoredTeam/boring.notch/blob/1f965d8b5ec950d3e407cbc63695ba8d90a03ac1/boringNotch/components/Shelf/Services/ShelfPersistenceService.swift)
- [Plasma scripting API](https://develop.kde.org/docs/plasma/scripting/api/)
- Lokalne definicje QML typów MPRIS i battery dostarczone przez Plasma 6.6.6.


## Integracje dodane w 0.2

KDE Connect jest ładowany dopiero po otwarciu strony wysyłania, więc brak jego QML
nie blokuje muzyki i półki. DevicesModel filtruje sparowane i osiągalne urządzenia;
PluginChecker kontroluje dostępność funkcji share. Wywołanie shareUrl jest
asynchroniczne. Wynik D-Bus potwierdza przyjęcie żądania, nie fizyczny transfer.
Ostateczny postęp i błędy należą do usług KDE Connect.

CalendarBackend wykrywa dostawcę pimevents po ID metadanych. DaysModel dostarcza
wydarzenia dla daty; wtyczka PIM odpowiada za Akonadi, powtórzenia i dane kalendarzy.
Test z natywną wtyczką wykrył cache agendy Plasma 6.6, który dla późno dostarczonych
danych spoza dzisiejszej daty zwracał starą pustą listę. Adapter odświeża klucz cache
przed odczytem wybranego dnia; test obejmuje przekroczenie granicy miesiąca i roku.
Nie dodano osobnego parsera ICS ani synchronizacji kont.
