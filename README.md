# Boring Island — plasmoid dla KDE Plasma

Natywna implementacja dla Linuksa inspirowana gałęzią `dev` projektu
[boring.notch](https://github.com/TheBoredTeam/boring.notch/tree/dev).
Wersja 0.2.0; wymagana **Plasma 6.6+**. Nie jest to pełny port wszystkich funkcji macOS.

![Dynamic Island](docs/dynamic-island.png)

## Instalacja

W katalogu tego projektu uruchom:

```bash
./scripts/install.sh
```

Albo zainstaluj gotowy `boring-island-0.2.0.plasmoid` przez „Dodaj elementy interfejsu” →
„Pobierz nowe elementy interfejsu” → „Zainstaluj z pliku lokalnego”.
Dodaj **Boring Island** do pulpitu lub górnego panelu.
Plasma zapisuje widżet i jego konfigurację: po kolejnym logowaniu przywraca go sama.
Nie potrzeba osobnej usługi ani autostartu.

Opcjonalnie, po instalacji:

```bash
./scripts/add-top-panel.sh
```

Ten skrypt tworzy mały, wyśrodkowany panel na górze ekranu; nie usuwa istniejących
paneli i nie dodaje drugiej kopii, jeśli znajdzie widżet w panelu. Skrypt jest
opcjonalnym narzędziem wdrożeniowym; nie był wykonywany na rzeczywistym pulpicie
użytkownika podczas przygotowania pakietu. Na komputerze z istniejącym górnym
panelem lepiej dodać widżet do niego ręcznie, aby uniknąć nakładania paneli.

PPM → ustawienia Boring Island → **Appearance and behavior**:

- **Notch** — płaska górna krawędź i zaokrąglony dół.
- **Dynamic Island** — zaokrąglona kapsuła; ustawienie domyślne.
- Szerokość, opóźnienie najechania, pokazywanie baterii i ograniczenie animacji.

Dla efektu wyspy włącz pływający panel w ustawieniach Plasma. Dla notch wyłącz
pływanie i ustaw górną krawędź. Motyw Plasma nadal decyduje o tle i marginesach
samego panelu. Plasmoid nie zastępuje całego panelu ani nie tworzy niezależnej
warstwy ponad wszystkimi oknami. W panelu rozwija się standardowy popup Plasma;
na pulpicie rozwija się zawartość widżetu. Nie emuluje fizycznego wycięcia ekranu.

## Funkcje

- Sterowanie aktywnym odtwarzaczem przez MPRIS: poprzedni/następny, play/pause,
  okładka, tytuł, wykonawca, pozycja, przewijanie i głośność **odtwarzacza**.
- Automatyczny wybór odtwarzacza przez model KDE; przyciski uwzględniają jego możliwości.
- Zegar w stanie bez muzyki, data w rozwinięciu.
- Wydarzenia kalendarzy KDE/Akonadi: agenda wybranego dnia, godziny, wydarzenia całodniowe,
  kolory kalendarzy, przechodzenie między dniami i odświeżanie.
- Wysyłanie pliku z półki przez KDE Connect: przycisk ↗, wybór sparowanego i osiągalnego
  urządzenia, przycisk Send. Widżet nie wysyła niczego automatycznie po upuszczeniu pliku.
- Zbiorczy status wewnętrznej baterii oraz podłączenia zasilania. Na komputerze bez
  baterii wskaźnik znika. `+` oznacza zewnętrzne zasilanie, nie gwarancję ładowania.
- Półka do 24 lokalnych plików/katalogów: upuść pliki, kliknij, aby otworzyć,
  przeciągnij do innej aplikacji, usuń skrót przyciskiem ×.
- Półka zapisuje tylko adresy, nie kopiuje i nie usuwa plików. Przeniesienie lub
  usunięcie oryginału unieważnia skrót. Nie otwiera plików automatycznie po upuszczeniu.
- Konfiguracja i półka osobno dla każdej instancji widżetu; bez zewnętrznego demona.

Spotify, VLC, Elisa i przeglądarki mogą udostępniać MPRIS, ale zakres sterowania
zależy od aplikacji. Pusta lista oznacza brak aktywnego źródła MPRIS. Głośność
odtwarzacza nie jest regulacją całego systemu. Okładki mogą być pobierane z URL
przekazanych przez odtwarzacz.

## KDE Connect i kalendarze

**KDE Connect:** zainstaluj KDE Connect na komputerze i urządzeniu odbiorczym,
połącz je w tej samej sieci i sparuj. Wtyczka „Udostępnianie i odbieranie” musi być
włączona. Na półce kliknij ↗ obok pliku, następnie Send przy urządzeniu. Przycisk
⚙ otwiera ustawienia parowania. Wyświetlane są urządzenia sparowane i osiągalne;
nieaktywna funkcja udostępniania blokuje przycisk. Plasmoid przekazuje żądanie do
KDE Connect — komunikat o przekazaniu nie oznacza dostarczenia pliku. Postęp i
ostateczne błędy pokazują powiadomienia KDE Connect. Katalog najpierw spakuj do
archiwum; wysyłanie katalogów nie jest funkcją tej integracji.

**Kalendarze:** potrzebna jest wtyczka Plasma Calendar „Calendar Events” / „Wydarzenia
w kalendarzu” (`pimevents`) oraz skonfigurowane kalendarze Akonadi/KOrganizer.
Na Ubuntu wtyczkę dostarcza `kdepim-addons`. Nie jest dołączona do paczki plasmoidu.
W ustawieniach zegara Plasma otwórz sekcję kalendarza, włącz wydarzenia PIM i wybierz
kalendarze. Widżet używa tego samego wyboru w procesie Plasma; nie kopiuje wydarzeń
ani nie przechowuje haseł kont. Po doinstalowaniu wtyczki ponownie załaduj widżet.
Tryb `plasmawindowed` ma własną konfigurację procesu, więc nie musi widzieć wyboru
kalendarzy z `plasmashell` — docelowe miejsce to panel/pulpit Plasma.
Jeżeli wtyczki brakuje, widżet pokazuje instrukcję zamiast pustej agendy. To agenda
odczytu: dodawanie/edycję wydarzeń wykonuj w KOrganizer.

## Zakres i ograniczenia

Nie przeniesiono: AirDrop, kamery, tekstów piosenek, historii schowka, pełnej kolejki powiadomień, pomiarowego
wizualizatora audio, zamienników systemowego OSD ani wykrywania pełnego ekranu.
Szczegółowe porównanie źródeł: [docs/ANALIZA.md](docs/ANALIZA.md).

Moduły MPRIS i baterii są **prywatnym API Plasma**. Zweryfikowane środowisko:
Plasma 6.6.6 / Qt 6.10.2, Ubuntu 26.04. Nie deklarujemy zgodności z Plasma 5 ani
ze starszą Plasma 6; przyszłe zmiany tych modułów mogą wymagać aktualizacji.

## Testy i rozwój

```bash
./scripts/test.sh
python3 ./scripts/package.py  # wynik: build/boring-island-0.2.0.plasmoid
plasmawindowed ./package
```

Testy wymagają Qt Quick Test (`qmltestrunner`), `dbus-run-session`, `python3-dbus`
i `python3-gi`; moduły KDE Connect są potrzebne do testu wysyłania. Te zależności testowe nie są wymagane do korzystania z widżetu.
Na dystrybucjach z inną ścieżką ustaw `QMLTESTRUNNER`.

Dodatkowy test natywnego dostawcy kalendarza (wymaga CMake, kompilatora C++, Qt 6
Core development i nagłówków `libkf6declarative-dev`):

```bash
./scripts/test-calendar-plugin.sh
```

Buduje lokalną wtyczkę testową, która emituje kontrolowane wydarzenia. Nie instaluj
jej do systemu — służy wyłącznie testom. Sprawdza wykrycie dostawcy, asynchroniczne
wydarzenia, zmianę miesiąca/roku oraz przeładowanie bez duplikowania wyników.

Zweryfikowano: testy QML, MPRIS i KDE Connect na izolowanym D-Bus, natywną testową
wtyczkę kalendarza, renderowanie widoków,
instalację KPackage do katalogu testowego oraz ładowanie przez `plasmawindowed`
w trybie offscreen. Testy MPRIS używają rzeczywistego D-Bus i testowego odtwarzacza,
a obrazy prezentują dane testowe. Test KDE Connect nie wysyła danych do prawdziwego
urządzenia; test kalendarza nie łączy się z prywatnymi kontami Akonadi. Nie wykonano końcowego testu interaktywnego
panelu Wayland, fizycznej baterii, przeciągania między aplikacjami ani ponownego
logowania, fizycznego transferu do telefonu ani synchronizacji konta kalendarza. Te scenariusze pozostają do sprawdzenia na docelowym pulpicie.

Odinstalowanie: najpierw usuń widżet z panelu/pulpitu, następnie:

```bash
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.boringisland
```

Licencja GPL-3.0-only. Autorzy i źródło inspiracji: [NOTICE.md](NOTICE.md).
