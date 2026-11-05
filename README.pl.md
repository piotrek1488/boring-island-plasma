# Boring Island — plasmoid dla KDE Plasma

[English](README.md) | **Polski**

Natywna implementacja dla Linuksa inspirowana gałęzią `dev` projektu
[boring.notch](https://github.com/TheBoredTeam/boring.notch/tree/dev).
Wersja 0.3.0; wymagana **Plasma 6.6+**. Nie jest to pełny port wszystkich funkcji macOS.

![Dynamic Island po polsku](docs/dynamic-island-pl.png)

## Instalacja

W katalogu tego projektu uruchom:

```bash
./scripts/install.sh
```

Albo zainstaluj gotowy `boring-island-0.3.0.plasmoid` przez „Dodaj elementy interfejsu” →
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

PPM → ustawienia Boring Island → **Boring Island**:

- **Language / Język** — domyślnie English, opcjonalnie Polski. Wybór jest zapisywany
  osobno dla każdego widżetu i działa niezależnie od języka systemu.
- **Notch** — płaska górna krawędź i zaokrąglony dół.
- **Dynamic Island** — zaokrąglona kapsuła; ustawienie domyślne.
- **Dopasuj wysokość do panelu** — domyślnie włączone; widżet korzysta z wysokości
  przydzielonej przez Plasma.
- Wyłącz automatyczne dopasowanie, aby ustawić **Wysokość zwiniętego widżetu (px)**
  w zakresie 16–128. Widoczna wysokość nie przekroczy dostępnego miejsca w panelu.
  Tekst, wskaźnik i odstępy skalują się razem z wysokością; szerokość ustawisz osobno.
- Mniejszy notch przylega do góry przydzielonego obszaru, a wyspa jest wyśrodkowana
  w pionie. Na pulpicie automatyczna wysokość wynosi 42 px.
- Wymiary są podane w pikselach logicznych Qt — nadal obowiązuje skalowanie ekranu.
  Marginesami panelu zarządza Plasma. Rozwinięty widok ma osobną szerokość, wysokość i skalę 60–200%.
- Opóźnienie najechania, pokazywanie baterii i ograniczenie animacji.

Nazwy urządzeń, plików, utworów i treść wydarzeń pozostają w oryginalnym języku.
Zewnętrzne okna KDE i szczegóły błędów usług używają własnych ustawień języka.

Dla efektu wyspy włącz pływający panel w ustawieniach Plasma. Dla notch wyłącz
pływanie i ustaw górną krawędź. Motyw Plasma nadal decyduje o tle i marginesach
samego panelu. Plasmoid nie zastępuje całego panelu ani nie tworzy niezależnej
warstwy ponad wszystkimi oknami. W panelu otwiera się okno Plasma bez ramki, nakładane na pozycję widżetu.
Nagłówek i treść tworzą jeden animowany kształt bez odstępu motywu.
Na pulpicie używany jest ten sam komponent. Nie emuluje fizycznego wycięcia ekranu.

## Powiadomienia, aktywność i aktualizacja

- **Podgląd powiadomień:** domyślnie 4 sekundy, do zmiany w ustawieniach (1–60 s).
  Podglądy tworzą kolejkę do 20 oczekujących wpisów. Upływ czasu chowa podgląd,
  pozostawiając wpis w historii KDE. Po najechaniu wybierz zakładkę **Powiadomienia**.
- **Usuwanie:** × usuwa wpis, „Usuń wszystkie” czyści listę. Widżet i centrum
  powiadomień korzystają ze wspólnego modelu Plasma, więc usunięcie działa w obie
  strony. Stara historia nie jest ponownie wyświetlana po uruchomieniu widżetu.
  Respektowane są tryb Nie przeszkadzać i ustawienia aplikacji. Powiadomienia
  tymczasowe podlegają regułom przechowywania KDE; nie tworzymy osobnego archiwum.
- **Priorytety:** podgląd powiadomienia → operacja na pakietach → odtwarzana muzyka
  → lokalny model AI → zegar. W ustawieniach lub zakładce **Aktywność** można
  przypiąć konkretny widok. Podgląd chwilowo przerywa przypięcie, po czym je przywraca.
- **System:** CPU, RAM i obsługiwane GPU (liczniki sysfs, opcjonalnie `nvidia-smi`/`intel_gpu_top`).
  Nieobsługiwane GPU są pomijane. ↗ otwiera Monitor systemu lub `top` w Konsole.
- **Pakiety:** wykrywanie poleceń APT/dpkg, pacman, DNF/Yum, Zypper, Flatpak, pip
  i npm. Pasek sygnalizuje aktywność bez rzeczywistego procentu. Zniknięcie procesu
  nie oznacza potwierdzonej udanej instalacji. Ukrytych procesów nie da się wykryć;
  operacje Discover/PackageKit nie są gwarantowane. Pokazanie terminala wymaga
  opcjonalnego `kdotool` i zgody mechanizmu aktywacji okien Wayland.
- **Lokalne AI:** opcjonalnie, domyślnie wyłączone. LM Studio na porcie 1234
  (REST v1 lub v0) i Ollama na 11434: model, kontekst, dostępne dane pamięci i CPU.
  Stan generowania i tok/s są dostępne tylko, gdy proces inferencji LM Studio
  udostępnia lokalne `/slots` z licznikami wygenerowanych tokenów.
  Nieznane wartości nie są zgadywane. Uwierzytelnione API, inne porty serwera
  i pomiar tok/s Ollamy nie są obsługiwane.
- **Multimedia:** przycisk pokazania odtwarzacza, jeśli obsługuje to MPRIS,
  i nazwa wyjścia audio przez opcjonalne `pactl`. Pulsujący wskaźnik jest dekoracyjny.
- **Rozmiar:** wybór Notch/Dynamic Island, automatyczna lub ręczna wysokość,
  szerokość 80–1000 px, automatyczna szerokość z limitem oraz osobne wymiary
  i skala rozwinięcia. Opcja ograniczenia animacji wyłącza animację rozwijania.

Monitoring wymaga **Python 3** i modułu Plasma `org.kde.plasma.plasma5support`.
Krótki proces zbiera dane co około 3 sekundy, bez usługi i autostartu. Poszczególne
moduły można wyłączyć. Integracja powiadomień korzysta z `org.kde.notificationmanager`
wewnątrz procesu **plasmashell**; osobny `plasmawindowed` nie współdzieli jego historii.
Standardowe dymki KDE nadal podlegają ustawieniom systemowym; widżet ich globalnie
nie wyłącza. Nowe pozycjonowanie na Waylandzie i synchronizacja usuwania wymagają
jeszcze sprawdzenia na rzeczywistym pulpicie Plasma 6.6+.

W lokalnym klonie repozytorium zbuduj pakiet i zaktualizuj istniejący widżet:

```bash
git pull --ff-only origin main
python3 scripts/package.py
kpackagetool6 --type Plasma/Applet --upgrade build/boring-island-0.3.0.plasmoid
systemctl --user restart plasma-plasmashell.service
```

Przy pierwszej instalacji użyj `--install` zamiast `--upgrade`. Restart przeładuje
pulpit i panele bez wylogowania; aplikacje pozostaną uruchomione. Ustawienia
widżetu i półka zostaną zachowane. Alternatywnie `./scripts/install.sh`
automatycznie wybiera instalację lub aktualizację bezpośrednio ze źródeł.

Testy podstawowe bez Plasma: `./scripts/test-core.sh`. Test natywnej synchronizacji
na Plasma 6.6+ z `gdbus`: `./scripts/test-notifications.sh` — skrypt sam tworzy
izolowaną sesję D-Bus. Nie uruchamiaj jego pliku QML na magistrali swojego pulpitu.
Szczegóły wykonanych i niewykonanych testów: [TESTING.md](docs/TESTING.md).

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

Nie przeniesiono: AirDrop, kamery, tekstów piosenek, historii schowka, pomiarowego
wizualizatora audio, zamienników systemowego OSD ani wykrywania pełnego ekranu.
Szczegółowe porównanie źródeł: [docs/ANALIZA.md](docs/ANALIZA.md).

Moduły MPRIS, baterii, okna i powiadomień są **prywatnym API Plasma**.
Wcześniejsze wersje sprawdzano na Plasma 6.6.6 / Qt 6.10.2, Ubuntu 26.04.
Testy podstawowe 0.3.0 wykonano na Qt 6.4.2 bez sesji Plasma. Nie deklarujemy zgodności z Plasma 5 ani
ze starszą Plasma 6; przyszłe zmiany tych modułów mogą wymagać aktualizacji.

## Testy i rozwój

```bash
./scripts/test.sh
python3 ./scripts/package.py  # wynik: build/boring-island-0.3.0.plasmoid
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

Dla wcześniejszej wersji 0.2.2 zweryfikowano: testy QML, MPRIS i KDE Connect na izolowanym D-Bus, natywną testową
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
