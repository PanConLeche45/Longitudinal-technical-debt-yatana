#!/usr/bin/env python3
"""
export_sonar_file_metrics.py — E1 por archivo desde SonarQube (continuación del instrumento de CIMPS)

CIMPS midió 16 indicadores de SonarQube a nivel PROYECTO. Este script obtiene los mismos
indicadores a nivel ARCHIVO (qualifier FIL, sólo código de producción) desde la API Web de un
SonarQube local, para el snapshot analizado, y los escribe con la llave de integración
project + artifact_id + decision_time.

Uso (Git Bash; el token se lee de la variable de entorno, nunca se escribe en archivos):
  export SONAR_TOKEN=...            # token generado en http://localhost:9000 (Mi cuenta → Seguridad)
  python sprint2_E3/scripts/export_sonar_file_metrics.py \
      --sonar-url http://localhost:9000 --project-key commons-collections_4.5.0_7f7fb0244 \
      --project commons-collections --decision-time 2025-04-19 \
      --decision-sha 7f7fb0244abc940a2e9dd28b67508c0483a58c3e \
      --artifacts sprint2_E3/data/ARTIFACTS_commons-collections.csv \
      --out sprint2_E3/data

Salidas:
  E1_FILE_METRICS_<project>_<decision_time>.csv   una fila por archivo de producción
  E1_RUN_MANIFEST_<project>_<decision_time>.json  versión del servidor, perfil de calidad,
                                                   fecha de análisis, métricas, comando
Sólo biblioteca estándar (Python ≥ 3.8).
"""
import argparse, base64, csv, json, os, sys, urllib.error, urllib.parse, urllib.request
from datetime import datetime, timezone

METRICS = ["ncloc", "functions", "classes", "complexity", "cognitive_complexity",
           "code_smells", "sqale_index", "bugs", "vulnerabilities", "security_hotspots",
           "violations", "duplicated_lines_density", "sqale_rating", "reliability_rating",
           "security_rating"]
PER_KLOC = ["sqale_index", "code_smells", "bugs", "vulnerabilities", "violations", "complexity"]
# SonarQube no guarda en archivos las medidas iguales a su "mejor valor" (optimizedBestValue): un
# archivo sin issues no trae code_smells, etc. en la respuesta. Ausente = 0 para estas métricas (E-09).
ZERO_IF_ABSENT = ["code_smells", "sqale_index", "bugs", "vulnerabilities", "security_hotspots",
                  "violations", "duplicated_lines_density"]
PROJECT_METRICS = ["ncloc", "code_smells", "sqale_index", "bugs", "vulnerabilities", "violations"]


def api(base, path, token, **params):
    url = f"{base.rstrip('/')}/{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", "Basic " + base64.b64encode(f"{token}:".encode()).decode())
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            body = r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            sys.exit(f"SonarQube respondió {e.code} en {path}: el token no puede leer métricas. "
                     "Usa un 'User Token' (squ_), no un 'Global Analysis Token' (sqa_).")
        raise
    return json.loads(body) if body.strip().startswith(("{", "[")) else body


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sonar-url", default="http://localhost:9000")
    ap.add_argument("--project-key", required=True)
    ap.add_argument("--project", required=True)
    ap.add_argument("--decision-time", required=True)
    ap.add_argument("--decision-sha", required=True)
    ap.add_argument("--artifacts", required=True, help="registro artifact_id,path")
    ap.add_argument("--src-prefix", default="src/main/java/")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    token = os.environ.get("SONAR_TOKEN")
    if not token:
        sys.exit("Falta la variable de entorno SONAR_TOKEN")

    amap = {}
    with open(a.artifacts, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            amap[r["path"]] = r["artifact_id"]

    rows, page, filled = [], 1, {k: 0 for k in ZERO_IF_ABSENT}
    while True:
        d = api(a.sonar_url, "api/measures/component_tree", token, component=a.project_key,
                metricKeys=",".join(METRICS), qualifiers="FIL", ps=500, p=page)
        for c in d["components"]:
            path = c.get("path", "")
            if not (path.startswith(a.src_prefix) and path.endswith(".java")):
                continue                                    # sólo producción, como CIMPS
            m = {x["metric"]: x.get("value", "") for x in c.get("measures", [])}
            row = {"project": a.project, "artifact_id": amap.get(path, ""),
                   "decision_time": a.decision_time, "path": path}
            for k in METRICS:
                row[k] = m.get(k, "")
                if row[k] == "" and k in ZERO_IF_ABSENT:
                    row[k] = "0"
                    filled[k] += 1
            try:
                kloc = float(row["ncloc"]) / 1000.0
            except ValueError:
                kloc = 0.0
            for k in PER_KLOC:
                try:
                    row[f"{k}_per_kloc"] = round(float(row[k]) / kloc, 4) if kloc > 0 else ""
                except ValueError:
                    row[f"{k}_per_kloc"] = ""
            rows.append(row)
        total = d["paging"]["total"]
        if page * 500 >= total:
            break
        page += 1

    os.makedirs(a.out, exist_ok=True)
    outp = os.path.join(a.out, f"E1_FILE_METRICS_{a.project}_{a.decision_time}.csv")
    cols = ["project", "artifact_id", "decision_time", "path"] + METRICS + [f"{k}_per_kloc" for k in PER_KLOC]
    with open(outp, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        w.writerows(sorted(rows, key=lambda r: r["path"]))

    # ---- provenance --------------------------------------------------------------------
    version = api(a.sonar_url, "api/server/version", token)
    try:
        qp = api(a.sonar_url, "api/qualityprofiles/search", token, project=a.project_key)
        profiles = [{"language": p["language"], "name": p["name"], "key": p["key"],
                     "isDefault": p.get("isDefault"), "activeRuleCount": p.get("activeRuleCount")}
                    for p in qp.get("profiles", []) if p["language"] == "java"]
    except Exception as e:                                  # noqa: BLE001
        profiles = f"no disponible: {e}"
    try:
        an = api(a.sonar_url, "api/project_analyses/search", token, project=a.project_key, ps=1)
        last = an["analyses"][0] if an.get("analyses") else {}
    except Exception as e:                                  # noqa: BLE001
        last = f"no disponible: {e}"
    totals = {k: sum(float(r[k]) for r in rows if str(r[k]).replace(".", "", 1).isdigit())
              for k in PROJECT_METRICS}
    # Nivel proyecto (lo que reporta CIMPS) y archivos de prueba (UTS), para explicar diferencias.
    try:
        pj = api(a.sonar_url, "api/measures/component", token, component=a.project_key,
                 metricKeys=",".join(PROJECT_METRICS))
        project_totals = {x["metric"]: float(x["value"]) for x in pj["component"].get("measures", [])}
    except Exception as e:                                  # noqa: BLE001
        project_totals = f"no disponible: {e}"
    test_totals, tpage = {k: 0.0 for k in PROJECT_METRICS}, 1
    try:
        while True:
            t = api(a.sonar_url, "api/measures/component_tree", token, component=a.project_key,
                    metricKeys=",".join(PROJECT_METRICS), qualifiers="UTS", ps=500, p=tpage)
            for c in t["components"]:
                for x in c.get("measures", []):
                    test_totals[x["metric"]] += float(x.get("value") or 0)
            test_totals["test_files"] = test_totals.get("test_files", 0) + len(t["components"])
            if tpage * 500 >= t["paging"]["total"]:
                break
            tpage += 1
    except Exception as e:                                  # noqa: BLE001
        test_totals = f"no disponible: {e}"
    manifest = {
        "script": "sprint2_E3/scripts/export_sonar_file_metrics.py",
        "command": " ".join(sys.argv),
        "execution_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "sonarqube_version": version,
        "project_key": a.project_key,
        "project": a.project, "decision_time": a.decision_time, "decision_sha": a.decision_sha,
        "quality_profiles": profiles,
        "last_analysis": last,
        "metrics": METRICS, "per_kloc": PER_KLOC,
        "files_exported": len(rows),
        "files_in_artifact_registry": sum(1 for r in rows if r["artifact_id"]),
        "file_level_totals": totals,
        "absent_filled_with_zero": filled,
        "project_level_totals": project_totals,
        "test_file_totals": test_totals,
        "note": "Totales por archivo comparables con la Tabla 2 de CIMPS (nivel proyecto) para "
                "verificar consistencia del instrumento; no son idénticos si cambia versión/perfil.",
    }
    with open(os.path.join(a.out, f"E1_RUN_MANIFEST_{a.project}_{a.decision_time}.json"),
              "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
    print(json.dumps({k: manifest[k] for k in ("sonarqube_version", "files_exported",
                      "files_in_artifact_registry", "file_level_totals",
                      "project_level_totals", "test_file_totals")}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
