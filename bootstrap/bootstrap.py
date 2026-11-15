#!/usr/bin/env python3
"""
Auto-configuración del stack (sin dependencias, solo librería estándar).

Modos:
  init       -> se ejecuta ANTES de qBittorrent: pre-siembra qBittorrent.conf
                (usuario/contraseña fijos, rutas, sin contraseña temporal).
  configure  -> se ejecuta DESPUÉS de levantar los servicios y conecta todo:
                * Sonarr/Radarr: auth, carpeta raíz, qBittorrent, notificación a Plex
                * Prowlarr: auth, FlareSolverr, sincronización con Sonarr/Radarr
                * Bazarr: conexión con Sonarr/Radarr
                * Plex: bibliotecas de Películas y Series
                * Overseerr: Plex + Sonarr + Radarr y finaliza el asistente inicial

Todas las operaciones son idempotentes: se puede volver a ejecutar sin duplicar nada
(`docker compose run --rm bootstrap`).

Las API keys NO se configuran a mano: se leen de los config.xml / config.yaml /
settings.json / Preferences.xml que cada app genera en su primer arranque.
"""

import base64
import configparser
import hashlib
import http.cookiejar
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

ENV = os.environ.get
ADMIN_USER = ENV("ADMIN_USER", "admin")
ADMIN_PASSWORD = ENV("ADMIN_PASSWORD", "")
QBIT_PORT = int(ENV("QBITTORRENT_WEBUI_PORT", "8089"))
QUALITY_PROFILE = ENV("QUALITY_PROFILE", "HD-1080p")
PLEX_LANGUAGE = ENV("PLEX_LANGUAGE", "es-ES")
WAIT_TIMEOUT = int(ENV("BOOTSTRAP_WAIT_TIMEOUT", "900"))
PLEX_WAIT_TIMEOUT = int(ENV("PLEX_WAIT_TIMEOUT", "300"))
PLEX_ADVERTISE_URL = ENV("PLEX_ADVERTISE_URL", "")  # solo macOS, lo pone setup.sh
# Indexers públicos que se agregan a Prowlarr la primera vez (definitionName de Prowlarr)
PROWLARR_INDEXERS = ["extratorrent-st", "kickasstorrents-to", "kickasstorrents-ws",
                     "limetorrents", "thepiratebay", "TorrentsCSV", "uindex", "yts"]

CFG = "/cfg"  # volúmenes de configuración montados aquí (ver docker-compose.yml)

warnings = []


def log(msg):
    print(f"[BOOTSTRAP] {msg}", flush=True)


def warn(msg):
    warnings.append(msg)
    log(f"⚠️  {msg}")


# --------------------------------------------------------------------------- HTTP
class HTTPError(Exception):
    def __init__(self, code, body):
        super().__init__(f"HTTP {code}: {body[:300]}")
        self.code = code
        self.body = body


def request(method, url, headers=None, body=None, form=None, opener=None, timeout=30):
    headers = dict(headers or {})
    headers.setdefault("Accept", "application/json")
    data = None
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with (opener or urllib.request.build_opener()).open(req, timeout=timeout) as r:
            raw = r.read().decode() or "null"
    except urllib.error.HTTPError as e:
        raise HTTPError(e.code, e.read().decode(errors="replace")) from None
    try:
        return json.loads(raw)
    except ValueError:
        return raw


def wait_until(name, fn, timeout=WAIT_TIMEOUT, interval=5):
    """Reintenta fn() hasta que devuelva algo truthy o se acabe el tiempo."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            result = fn()
            if result:
                return result
        except Exception as e:  # noqa: BLE001 - servicio aún arrancando
            last = e
        time.sleep(interval)
    raise TimeoutError(f"{name} no respondió en {timeout}s ({last})")


def read_file(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


# ------------------------------------------------------------------ qBittorrent
def qbit_password_hash(password):
    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac("sha512", password.encode(), salt, 100000, dklen=64)
    return f"@ByteArray({base64.b64encode(salt).decode()}:{base64.b64encode(key).decode()})"


def init_qbittorrent():
    conf_dir = f"{CFG}/qbittorrent/qBittorrent"
    conf_path = f"{conf_dir}/qBittorrent.conf"
    os.makedirs(conf_dir, exist_ok=True)

    ini = configparser.RawConfigParser(strict=False)
    ini.optionxform = str  # Qt distingue mayúsculas
    if os.path.exists(conf_path):
        ini.read(conf_path, encoding="utf-8")

    def setdefault(section, key, value):
        if not ini.has_section(section):
            ini.add_section(section)
        if not ini.has_option(section, key):
            ini.set(section, key, value)

    setdefault("LegalNotice", "Accepted", "true")
    setdefault("BitTorrent", "Session\\DefaultSavePath", "/downloads/")
    setdefault("BitTorrent", "Session\\TempPathEnabled", "true")
    setdefault("BitTorrent", "Session\\TempPath", "/downloads/incomplete/")
    setdefault("BitTorrent", "Session\\Port", ENV("TORRENTING_PORT", "6881"))
    setdefault("Preferences", "WebUI\\Port", str(QBIT_PORT))
    setdefault("Preferences", "WebUI\\Username", ADMIN_USER)
    # Evita bloqueos al entrar vía Caddy / nombre de host distinto
    setdefault("Preferences", "WebUI\\HostHeaderValidation", "false")

    if not ini.has_option("Preferences", "WebUI\\Password_PBKDF2"):
        if not ADMIN_PASSWORD:
            warn("ADMIN_PASSWORD vacío: qBittorrent generará una contraseña temporal")
        else:
            ini.set("Preferences", "WebUI\\Password_PBKDF2", f'"{qbit_password_hash(ADMIN_PASSWORD)}"')
            log("qBittorrent: contraseña de WebUI configurada")
    else:
        log("qBittorrent: ya tiene contraseña, no se modifica")

    with open(conf_path, "w", encoding="utf-8") as f:
        ini.write(f, space_around_delimiters=False)
    uid, gid = int(ENV("PUID", "1000")), int(ENV("PGID", "1000"))
    for root, dirs, files in os.walk(f"{CFG}/qbittorrent"):
        for p in [root] + [os.path.join(root, x) for x in dirs + files]:
            os.chown(p, uid, gid)
    log("qBittorrent: configuración inicial lista")


# ---------------------------------------------------------------- *arr helpers
class Arr:
    def __init__(self, name, host, port, api_version, cfg_dir):
        self.name, self.cfg_dir = name, cfg_dir
        self.base = f"http://{host}:{port}/api/{api_version}"
        self.host, self.port = host, port
        self.key = None

    def load_key(self):
        def _read():
            root = ET.fromstring(read_file(f"{self.cfg_dir}/config.xml"))
            return root.findtext("ApiKey")
        self.key = wait_until(f"{self.name} (config.xml)", _read)
        wait_until(self.name, lambda: self.get("system/status"))
        log(f"{self.name}: listo")
        return self

    def call(self, method, path, body=None):
        return request(method, f"{self.base}/{path}", {"X-Api-Key": self.key}, body)

    def get(self, path):
        return self.call("GET", path)

    def post(self, path, body):
        return self.call("POST", path, body)

    def put(self, path, body):
        return self.call("PUT", path, body)


def fill_schema(item, values):
    """Asigna valores a los 'fields' de un esquema de la API de Servarr."""
    for field in item.get("fields", []):
        if field["name"] in values:
            field["value"] = values[field["name"]]
    return item


def schema_for(arr, resource, implementation):
    for item in arr.get(f"{resource}/schema"):
        if item["implementation"] == implementation:
            return item
    raise RuntimeError(f"{arr.name}: no existe {implementation} en {resource}/schema")


def add_once(arr, resource, implementation, name, values, extra=None):
    existing = arr.get(resource)
    if any(x.get("implementation") == implementation for x in existing):
        log(f"{arr.name}: {implementation} ya configurado en {resource}")
        return
    item = fill_schema(schema_for(arr, resource, implementation), values)
    item.update({"name": name, "enable": True, **(extra or {})})
    wait_until(f"{arr.name} → {name}", lambda: arr.post(resource, item), timeout=180, interval=10)
    log(f"{arr.name}: {name} agregado ({resource})")


def setup_auth(arr):
    if not ADMIN_PASSWORD:
        return
    host = arr.get("config/host")
    if host.get("username") and host.get("authenticationMethod", "none") != "none":
        log(f"{arr.name}: autenticación ya configurada")
        return
    host.update({
        "authenticationMethod": "forms",
        # Login siempre (las versiones nuevas exigen Allowed Hosts para eximir la red local)
        "authenticationRequired": "enabled",
        "username": ADMIN_USER,
        "password": ADMIN_PASSWORD,
        "passwordConfirmation": ADMIN_PASSWORD,
    })
    arr.put(f"config/host/{host['id']}", host)
    log(f"{arr.name}: login configurado (usuario '{ADMIN_USER}')")


def setup_root_folder(arr, path):
    if any(r["path"].rstrip("/") == path for r in arr.get("rootfolder")):
        log(f"{arr.name}: carpeta raíz {path} ya existe")
        return
    arr.post("rootfolder", {"path": path})
    log(f"{arr.name}: carpeta raíz {path} agregada")


def setup_download_client(arr, category_field, category):
    add_once(arr, "downloadclient", "QBittorrent", "qBittorrent", {
        "host": "qbittorrent",
        "port": QBIT_PORT,
        "useSsl": False,
        "username": ADMIN_USER,
        "password": ADMIN_PASSWORD,
        category_field: category,
    }, {"priority": 1, "removeCompletedDownloads": True, "removeFailedDownloads": True})


def setup_plex_notification(arr, token):
    existing = arr.get("notification")
    if any(x.get("implementation") == "PlexServer" for x in existing):
        log(f"{arr.name}: notificación a Plex ya configurada")
        return
    item = fill_schema(schema_for(arr, "notification", "PlexServer"), {
        "host": "plex", "port": 32400, "useSsl": False,
        "authToken": token, "updateLibrary": True,
    })
    for k, v in list(item.items()):
        if k.startswith("supportsOn") and v is True:
            item["on" + k[len("supportsOn"):]] = True
    item["name"] = "Plex"
    arr.post("notification", item)
    log(f"{arr.name}: actualizará la biblioteca de Plex al importar")


def pick_profile(arr):
    profiles = arr.get("qualityprofile")
    for p in profiles:
        if p["name"].lower() == QUALITY_PROFILE.lower():
            return p
    return profiles[0]


# ---------------------------------------------------------------------- Prowlarr
def setup_prowlarr(prowlarr, sonarr, radarr):
    # FlareSolverr como proxy (se aplica a indexers con la etiqueta 'flaresolverr')
    tag = next((t for t in prowlarr.get("tag") if t["label"] == "flaresolverr"), None) \
        or prowlarr.post("tag", {"label": "flaresolverr"})
    if not any(p.get("implementation") == "FlareSolverr" for p in prowlarr.get("indexerProxy")):
        item = fill_schema(schema_for(prowlarr, "indexerProxy", "FlareSolverr"),
                           {"host": "http://flaresolverr:8191/", "requestTimeout": 60})
        item.update({"name": "FlareSolverr", "tags": [tag["id"]]})
        wait_until("Prowlarr → FlareSolverr", lambda: prowlarr.post("indexerProxy", item),
                   timeout=300, interval=10)
        log("Prowlarr: FlareSolverr agregado (usa la etiqueta 'flaresolverr' en indexers con Cloudflare)")
    else:
        log("Prowlarr: FlareSolverr ya configurado")

    # Indexers públicos por defecto, solo en un Prowlarr sin indexers (respeta los que borres)
    if prowlarr.get("indexer"):
        log("Prowlarr: ya tiene indexers, no se agregan los de por defecto")
    else:
        profile = prowlarr.get("appprofile")[0]["id"]
        # La primera vez Prowlarr descarga las definiciones y tarda más que el timeout
        schemas = wait_until("Prowlarr (definiciones)", lambda: prowlarr.get("indexer/schema"))
        schemas = {s.get("definitionName"): s for s in schemas}
        for name in PROWLARR_INDEXERS:
            item = schemas.get(name)
            if not item:
                warn(f"Prowlarr: no existe el indexer '{name}'")
                continue
            cloudflare = any(f["name"] == "info_flaresolverr" for f in item["fields"])
            enable = item["enable"]
            item.update({"appProfileId": profile, "enable": False,
                         "tags": [tag["id"]] if cloudflare else []})
            # Prowlarr prueba el sitio al crear un indexer activo y lo rechaza si tarda
            # (forceSave no lo evita al crear): se crea apagado y se activa sin probar
            created = step(f"Prowlarr indexer {name}", prowlarr.post, "indexer", item)
            if created and enable:
                created["enable"] = True
                step(f"Prowlarr indexer {name}", prowlarr.put,
                     f"indexer/{created['id']}?forceSave=true", created)
        log(f"Prowlarr: indexers por defecto agregados ({', '.join(PROWLARR_INDEXERS)})")

    for app in (sonarr, radarr):
        if any(a.get("implementation") == app.name for a in prowlarr.get("applications")):
            log(f"Prowlarr: {app.name} ya sincronizado")
            continue
        item = fill_schema(schema_for(prowlarr, "applications", app.name), {
            "prowlarrUrl": "http://prowlarr:9696",
            "baseUrl": f"http://{app.host}:{app.port}",
            "apiKey": app.key,
        })
        item.update({"name": app.name, "syncLevel": "fullSync"})
        wait_until(f"Prowlarr → {app.name}", lambda: prowlarr.post("applications", item),
                   timeout=180, interval=10)
        log(f"Prowlarr: {app.name} agregado (los indexers se sincronizan solos)")


# ------------------------------------------------------------------------ Bazarr
def bazarr_key():
    base = f"{CFG}/bazarr/config"
    yaml_path, ini_path = f"{base}/config.yaml", f"{base}/config.ini"
    if os.path.exists(yaml_path):
        section = None
        for line in read_file(yaml_path).splitlines():
            if line and not line[0].isspace():
                section = line.split(":")[0].strip()
            elif section == "auth" and line.strip().startswith("apikey:"):
                return line.split(":", 1)[1].strip().strip("'\"")
    if os.path.exists(ini_path):
        ini = configparser.RawConfigParser()
        ini.read(ini_path)
        return ini.get("auth", "apikey", fallback=None)
    return None


def setup_bazarr(sonarr, radarr):
    key = wait_until("Bazarr (config.yaml)", bazarr_key)
    url = "http://bazarr:6767/api/system/settings"
    headers = {"X-API-KEY": key}
    settings = wait_until("Bazarr", lambda: request("GET", url, headers))
    general = settings.get("general", {})
    if general.get("use_sonarr") and general.get("use_radarr"):
        log("Bazarr: Sonarr y Radarr ya conectados")
        return
    form = {
        "settings-general-use_sonarr": "true",
        "settings-sonarr-ip": "sonarr",
        "settings-sonarr-port": str(sonarr.port),
        "settings-sonarr-base_url": "/",
        "settings-sonarr-apikey": sonarr.key,
        "settings-general-use_radarr": "true",
        "settings-radarr-ip": "radarr",
        "settings-radarr-port": str(radarr.port),
        "settings-radarr-base_url": "/",
        "settings-radarr-apikey": radarr.key,
    }
    request("POST", url, headers, form=form)
    log("Bazarr: conectado a Sonarr y Radarr (elige idiomas de subtítulos en su UI)")


# -------------------------------------------------------------------------- Plex
def plex_token():
    prefs = f"{CFG}/plex/Library/Application Support/Plex Media Server/Preferences.xml"
    if not os.path.exists(prefs):
        return None
    return ET.fromstring(read_file(prefs)).get("PlexOnlineToken")


def plex(method, path, token, **params):
    qs = f"?{urllib.parse.urlencode(params)}" if params else ""
    return request(method, f"http://plex:32400{path}{qs}", {"X-Plex-Token": token})


def setup_plex_advertise(token):
    # Dirección extra que Plex publica en plex.tv para que la encuentren los clientes de la red
    wait_until("Plex", lambda: plex("PUT", "/:/prefs", token,
                                     customConnections=PLEX_ADVERTISE_URL) or True)
    log(f"Plex: anunciado en {PLEX_ADVERTISE_URL}")


def setup_plex_libraries(token):
    sections = wait_until("Plex", lambda: plex("GET", "/library/sections", token))
    sections = sections["MediaContainer"].get("Directory", [])
    # Red de respaldo: si falla el aviso de Sonarr/Radarr, Plex escanea solo cada hora
    plex("PUT", "/:/prefs", token, ScheduledLibraryUpdatesEnabled=1,
         ScheduledLibraryUpdateInterval=3600)
    paths = {loc["path"].rstrip("/") for s in sections for loc in s.get("Location", [])}
    libraries = [
        ("Películas", "movie", "tv.plex.agents.movie", "Plex Movie", "/movies"),
        ("Series", "show", "tv.plex.agents.series", "Plex TV Series", "/tv"),
    ]
    for name, kind, agent, scanner, path in libraries:
        if path in paths:
            log(f"Plex: biblioteca para {path} ya existe")
            continue
        # Recién reclamado, Plex ya permite leer pero da 403 al crear hasta terminar el claim
        wait_until(f"Plex biblioteca {name}", lambda: plex(
            "POST", "/library/sections", token, name=name, type=kind, agent=agent,
            scanner=scanner, language=PLEX_LANGUAGE, location=path) or True)
        log(f"Plex: biblioteca '{name}' creada ({path})")


# --------------------------------------------------------------------- Overseerr
def setup_overseerr(token, sonarr, radarr):
    base = "http://overseerr:5055/api/v1"
    jar = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    public = wait_until("Overseerr", lambda: request("GET", f"{base}/settings/public", opener=jar))
    headers = {}

    if public.get("initialized"):
        api_key = json.loads(read_file(f"{CFG}/overseerr/settings.json"))["main"]["apiKey"]
        headers = {"X-Api-Key": api_key}
    else:
        # El token del servidor pertenece al dueño de Plex -> queda como admin de Overseerr
        request("POST", f"{base}/auth/plex", body={"authToken": token}, opener=jar)
        log("Overseerr: sesión iniciada con la cuenta dueña de Plex")

    def call(method, path, body=None):
        return request(method, f"{base}/{path}", headers, body, opener=jar)

    if not call("GET", "settings/plex").get("ip"):
        call("POST", "settings/plex", {"ip": "plex", "port": 32400, "useSsl": False})
        log("Overseerr: Plex conectado")
    libs = call("GET", "settings/plex/library?sync=true")
    if libs and not any(lib.get("enabled") for lib in libs):
        ids = ",".join(str(lib["id"]) for lib in libs)
        call("GET", f"settings/plex/library?enable={ids}")
        log("Overseerr: bibliotecas de Plex habilitadas")

    for arr, path, extra in (
        (sonarr, "/tv", {"enableSeasonFolders": True, "activeAnimeProfileId": None,
                         "activeAnimeDirectory": None, "animeTags": []}),
        (radarr, "/movies", {"minimumAvailability": "released"}),
    ):
        resource = f"settings/{arr.name.lower()}"
        if call("GET", resource):
            log(f"Overseerr: {arr.name} ya configurado")
            continue
        profile = pick_profile(arr)
        call("POST", resource, {
            "name": arr.name, "hostname": arr.host, "port": arr.port, "apiKey": arr.key,
            "useSsl": False, "baseUrl": "", "activeProfileId": profile["id"],
            "activeProfileName": profile["name"], "activeDirectory": path,
            "is4k": False, "isDefault": True, "syncEnabled": True, "preventSearch": False,
            "externalUrl": "", "tags": [], **extra,
        })
        log(f"Overseerr: {arr.name} agregado (perfil '{profile['name']}')")

    if not public.get("initialized"):
        call("POST", "settings/initialize")
        log("Overseerr: asistente inicial completado")


# -------------------------------------------------------------------------- main
def step(name, fn, *args):
    try:
        return fn(*args)
    except Exception as e:  # noqa: BLE001 - seguimos con el resto de servicios
        warn(f"{name}: {e}")
        return None


def configure():
    if not ADMIN_PASSWORD:
        warn("ADMIN_PASSWORD vacío: se omite el login y la conexión con qBittorrent")

    sonarr = step("Sonarr", Arr("Sonarr", "sonarr", 8989, "v3", f"{CFG}/sonarr").load_key)
    radarr = step("Radarr", Arr("Radarr", "radarr", 7878, "v3", f"{CFG}/radarr").load_key)
    prowlarr = step("Prowlarr", Arr("Prowlarr", "prowlarr", 9696, "v1", f"{CFG}/prowlarr").load_key)

    for arr, path, cat_field, cat in ((sonarr, "/tv", "tvCategory", "tv-sonarr"),
                                      (radarr, "/movies", "movieCategory", "radarr")):
        if not arr:
            continue
        step(f"{arr.name} auth", setup_auth, arr)
        step(f"{arr.name} carpeta raíz", setup_root_folder, arr, path)
        if ADMIN_PASSWORD:
            step(f"{arr.name} qBittorrent", setup_download_client, arr, cat_field, cat)

    if prowlarr:
        step("Prowlarr auth", setup_auth, prowlarr)
    if prowlarr and sonarr and radarr:
        step("Prowlarr", setup_prowlarr, prowlarr, sonarr, radarr)
    if sonarr and radarr:
        step("Bazarr", setup_bazarr, sonarr, radarr)

    log("Esperando a que Plex esté reclamado (PLEX_CLAIM)...")
    token = step("Plex", wait_until, "Plex (token)", plex_token, PLEX_WAIT_TIMEOUT)
    if token:
        if PLEX_ADVERTISE_URL:
            step("Plex dirección", setup_plex_advertise, token)
        step("Plex bibliotecas", setup_plex_libraries, token)
        for arr in (sonarr, radarr):
            if arr:
                step(f"{arr.name} → Plex", setup_plex_notification, arr, token)
        if sonarr and radarr:
            step("Overseerr", setup_overseerr, token, sonarr, radarr)
    else:
        warn("Plex no está reclamado: pon un PLEX_CLAIM nuevo (https://plex.tv/claim), "
             "ejecuta 'docker compose up -d --force-recreate plex' y luego "
             "'docker compose run --rm bootstrap'")

    if warnings:
        log(f"Terminado con {len(warnings)} advertencia(s):")
        for w in warnings:
            log(f"  - {w}")
        sys.exit(1)
    log("✅ Todo configurado")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "configure"
    {"init": init_qbittorrent, "configure": configure}[mode]()
