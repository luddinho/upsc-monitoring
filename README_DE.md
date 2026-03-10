# USV-Überwachungsskript

**[🇬🇧 English Version](README.md)** | **[🇩🇪 Deutsche Version](#deutsche-version)**

Ein Bash-Skript zur Überwachung von Unterbrechungsfreien Stromversorgungen (USV) und zur Übermittlung der Metriken an InfluxDB für Echtzeit-Monitoring und Visualisierung.

## Funktionen

- **Echtzeit-USV-Überwachung**: Erfasst umfassende USV-Metriken über Network UPS Tools (NUT)
- **InfluxDB-Integration**: Speichert Zeitreihendaten in InfluxDB 2.x zur Visualisierung mit Grafana
- **Flexible Konfiguration**: Unterstützt Konfiguration über Datei oder Kommandozeilenargumente
- **Sichere Authentifizierung**: Token-basierte Authentifizierung mit Unterstützung für Token-Dateien
- **Umfassende Metriken**: Überwacht Batterie, Ein-/Ausgangsspannung, Frequenz, Last, Leistung und mehr
- **Fehlerbehandlung**: Robuste Fehlerprüfung und Validierung

## Voraussetzungen

- **Network UPS Tools (NUT)**: Der Befehl `upsc` muss verfügbar sein
  - Installation unter Debian/Ubuntu: `sudo apt-get install nut-client`
  - Installation unter macOS: `brew install nut` (Hinweis: upsc-Tool ist möglicherweise nicht über Homebrew auf macOS verfügbar)
  - Installation unter RHEL/CentOS: `sudo yum install nut-client`
- **curl**: Zum Senden von Daten an InfluxDB
- **InfluxDB 2.x**: Eine laufende InfluxDB-Instanz
- **Bash**: Version 4.0 oder höher

## Installation

1. Repository klonen oder herunterladen:
   ```bash
   git clone <repository-url>
   cd upsc-data
   ```

2. Skript ausführbar machen:
   ```bash
   chmod +x upsc-monitoring.sh
   ```

3. Beispiel-Konfigurationsdatei kopieren und anpassen:
   ```bash
   cp config/config.conf config/my-ups.conf
   ```

4. Konfigurationsdatei mit eigenen Einstellungen bearbeiten (siehe Konfigurationsabschnitt)

## Konfiguration

Erstellen Sie eine Konfigurationsdatei basierend auf dem Beispiel in `config/config.conf`:

```bash
# InfluxDB-Verbindungseinstellungen (ERFORDERLICH)
influx_server=http://192.168.1.100
influx_port=8086
influx_bucket=ups-monitoring
influx_org=home-network

# InfluxDB-Authentifizierung (verwenden Sie entweder influx_token oder influx_token_file)
influx_token=ihr-influxdb-token-hier
# influx_token_file=/pfad/zur/token.txt

# USV-Überwachungseinstellungen
ups_host=192.168.1.50
ups_port=3493
ups_name=ups
```

### Konfigurationsparameter

| Parameter | Beschreibung | Erforderlich | Standard |
|-----------|--------------|--------------|----------|
| `influx_server` | InfluxDB-Server-URL | Ja | - |
| `influx_port` | InfluxDB-Server-Port | Ja | - |
| `influx_bucket` | InfluxDB-Bucket-Name | Ja | - |
| `influx_org` | InfluxDB-Organisation | Ja | - |
| `influx_token` | InfluxDB-Authentifizierungstoken | Ja* | - |
| `influx_token_file` | Pfad zur Datei mit Token | Ja* | - |
| `ups_host` | USV-Host-IP-Adresse | Ja | - |
| `ups_port` | USV-NUT-Server-Port | Ja | - |
| `ups_name` | USV-Gerätename | Ja | - |

*Entweder `influx_token` oder `influx_token_file` muss angegeben werden.

## Verwendung

Skript mit Konfigurationsdatei ausführen:

```bash
./upsc-monitoring.sh -c config/my-ups.conf
```

Oder Hilfe anzeigen:

```bash
./upsc-monitoring.sh -h
```

## Überwachte Metriken

Das Skript erfasst folgende USV-Metriken:

| Metrik | Beschreibung | Typ |
|--------|--------------|-----|
| `battery_charge` | Batterieladung in Prozent | Numerisch |
| `battery_charge_low` | Schwellenwert für niedrige Batterie | Numerisch |
| `battery_runtime` | Geschätzte Batterielaufzeit (Sekunden) | Numerisch |
| `input_frequency` | Eingangsfrequenz (Hz) | Numerisch |
| `input_transfer_high` | Hoher Spannungs-Transferpunkt | Numerisch |
| `input_transfer_low` | Niedriger Spannungs-Transferpunkt | Numerisch |
| `input_voltage` | Eingangsspannung (V) | Numerisch |
| `input_voltage_extended` | Erweiterte Eingangsspannungsinformationen | String |
| `output_frequency` | Ausgangsfrequenz (Hz) | Numerisch |
| `output_frequency_nominal` | Nominale Ausgangsfrequenz | Numerisch |
| `output_voltage` | Ausgangsspannung (V) | Numerisch |
| `output_voltage_nominal` | Nominale Ausgangsspannung | Numerisch |
| `ups_beeper_status` | Signalton-Status | String |
| `ups_delay_shutdown` | Abschaltverzögerung (Sekunden) | Numerisch |
| `ups_delay_start` | Startverzögerung (Sekunden) | Numerisch |
| `ups_load` | USV-Last in Prozent | Numerisch |
| `ups_power` | Scheinleistung (VA) | Numerisch |
| `ups_power_nominal` | Nominale Leistung | Numerisch |
| `ups_realpower` | Wirkleistung (W) | Numerisch |
| `ups_status` | USV-Status (z.B. OL, OB) | String |
| `ups_timer_shutdown` | Abschalt-Timer-Wert | Numerisch |
| `ups_timer_start` | Start-Timer-Wert | Numerisch |

Alle Metriken werden in der InfluxDB-Messung `ups_status` mit einem `host`-Tag gespeichert.

## Automatisierung mit Cron

Um USV-Daten automatisch in regelmäßigen Abständen zu erfassen, fügen Sie einen Cron-Job hinzu:

```bash
# Crontab bearbeiten
crontab -e

# Eintrag hinzufügen, um alle 5 Minuten auszuführen
*/5 * * * * /pfad/zu/upsc-monitoring.sh -c /pfad/zu/config.conf
```

## Grafana-Dashboard

Der `config`-Ordner enthält Beispiel-Grafana-Dashboard-JSON-Dateien, die importiert werden können, um Ihre USV-Metriken zu visualisieren:

1. Grafana öffnen
2. Zu Dashboards → Import navigieren
3. Eine der JSON-Dateien aus dem `config`-Ordner hochladen
4. InfluxDB-Datenquelle auswählen
5. Dashboard nach Bedarf anpassen

## Fehlerbehebung

### Skript meldet "No data received from UPS"

- USV-Erreichbarkeit prüfen: `ping <ups_host>`
- NUT auf der USV prüfen: `upsc <ups_name>@<ups_host>:<ups_port>`
- Firewall-Regeln für Port 3493 überprüfen

### InfluxDB-Schreibvorgang schlägt fehl (HTTP-Statuscode != 204)

- InfluxDB läuft und ist erreichbar überprüfen
- Authentifizierungstoken ist gültig überprüfen
- Bucket und Organisation existieren sicherstellen
- Netzwerkverbindung zum InfluxDB-Server überprüfen

### Befehl nicht gefunden: upsc

- Network UPS Tools installieren: siehe Voraussetzungen
- `upsc` ist im PATH überprüfen: `which upsc`

## Lizenz

Dieses Projekt wird ohne Gewährleistung bereitgestellt. Frei zur Verwendung und Änderung für Ihre Bedürfnisse.

## Autor

- **Autor**: luddinho
- **Version**: 1.0.0
