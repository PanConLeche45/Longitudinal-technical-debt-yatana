#!/usr/bin/env python3
# =============================================================================
# parse_refactoring_events.py
#
# D4 (parte 2) - Normalizacion de la salida cruda de RefactoringMiner
#
# Proposito: RefactoringMiner entrega un JSON anidado (commits -> refactorings
# -> rangos de codigo). Para el analisis longitudinal se necesita una tabla
# plana donde cada fila sea UN evento de refactoring con su commit, fecha,
# tipo y archivos afectados, de modo que pueda cruzarse con el dataset de
# evolucion por (entity_id, commit).
#
# Genera dos salidas:
#   D4_REFACTORING_EVENTS_RAW.csv  - todos los eventos normalizados
#   D4_REFACTORING_AUDIT_30.csv    - muestra de 30 eventos para verificacion
#                                     manual contra el historial real de Git
#
# Uso:
#   python3 scripts/parse_refactoring_events.py <entrada.json> <repo> <dir_salida>
#
# Autor: Yatana Roa Moreno (ZS23020600)
# Proyecto: Continuidad post-CIMPS - Ruta B - Gate G1A
# =============================================================================

import json
import subprocess
import sys
import csv
import random
from collections import Counter
from pathlib import Path


def commit_metadata(repo, sha):
    """Obtiene fecha y autor del commit desde el repositorio local."""
    try:
        out = subprocess.run(
            ["git", "-C", repo, "log", "-1", "--format=%ad|%an|%s", "--date=short", sha],
            capture_output=True, text=True, timeout=30, check=True
        ).stdout.strip()
        parts = out.split("|", 2)
        return parts[0], parts[1], parts[2] if len(parts) > 2 else ""
    except Exception:
        return "NA", "NA", ""


def main():
    json_path = sys.argv[1]
    repo = sys.argv[2]
    outdir = Path(sys.argv[3])

    with open(json_path, encoding="utf-8") as fh:
        data = json.load(fh)

    commits = data.get("commits", [])
    print(f"Commits en la salida de RefactoringMiner: {len(commits)}")

    rows = []
    meta_cache = {}

    for commit in commits:
        sha = commit.get("sha1", "")
        refactorings = commit.get("refactorings", [])
        if not refactorings:
            continue

        if sha not in meta_cache:
            meta_cache[sha] = commit_metadata(repo, sha)
        fecha, autor, mensaje = meta_cache[sha]

        for idx, ref in enumerate(refactorings, start=1):
            tipo = ref.get("type", "UNKNOWN")
            descripcion = ref.get("description", "").replace("\n", " ").replace(",", ";")
            if len(descripcion) > 200:
                descripcion = descripcion[:200] + "..."

            # Archivos afectados: se toman de los rangos de codigo de destino
            archivos = set()
            for key in ("leftSideLocations", "rightSideLocations"):
                for loc in ref.get(key, []) or []:
                    fp = loc.get("filePath")
                    if fp:
                        archivos.add(fp)

            archivos_java = sorted(a for a in archivos if a.endswith(".java"))
            archivo_principal = archivos_java[0] if archivos_java else "NA"
            entity_id = Path(archivo_principal).stem if archivo_principal != "NA" else "NA"

            rows.append({
                "event_id": f"{sha[:9]}-{idx:03d}",
                "project_id": Path(repo).name,
                "commit": sha[:9],
                "commit_full": sha,
                "fecha": fecha,
                "autor": autor,
                "tipo_refactoring": tipo,
                "entity_id": entity_id,
                "archivo_principal": archivo_principal,
                "num_archivos_afectados": len(archivos_java),
                "descripcion": descripcion,
                "mensaje_commit": mensaje.replace(",", ";")[:120],
            })

    # --- Salida 1: todos los eventos ---------------------------------------
    raw_csv = outdir / "D4_REFACTORING_EVENTS_RAW.csv"
    campos = list(rows[0].keys()) if rows else []
    with open(raw_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=campos)
        w.writeheader()
        w.writerows(rows)
    print(f"Eventos normalizados: {len(rows)} -> {raw_csv}")

    # --- Distribucion por tipo ---------------------------------------------
    tipos = Counter(r["tipo_refactoring"] for r in rows)
    dist_csv = outdir / "D4_REFACTORING_TIPOS.csv"
    with open(dist_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["tipo_refactoring", "frecuencia", "porcentaje"])
        for tipo, n in tipos.most_common():
            w.writerow([tipo, n, f"{100 * n / len(rows):.2f}"])
    print(f"Tipos distintos: {len(tipos)} -> {dist_csv}")

    # --- Salida 2: muestra auditable de 30 eventos -------------------------
    # Muestreo reproducible: semilla fija para que la auditoria sea repetible.
    random.seed(20250930)
    muestra = random.sample(rows, min(30, len(rows)))
    muestra.sort(key=lambda r: (r["fecha"], r["event_id"]))

    audit_csv = outdir / "D4_REFACTORING_AUDIT_30.csv"
    with open(audit_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow([
            "event_id", "commit", "fecha", "tipo_refactoring", "entity_id",
            "archivo_principal", "descripcion",
            "comando_verificacion",
            "archivo_existe_en_commit", "veredicto_auditoria",
        ])
        for r in muestra:
            cmd = f'git -C {repo} show --stat {r["commit"]} | grep -c "{Path(r["archivo_principal"]).name}"'
            # Verificacion automatica: el archivo aparece en el commit?
            existe = "NO"
            if r["archivo_principal"] != "NA":
                try:
                    res = subprocess.run(
                        ["git", "-C", repo, "show", "--name-only", "--format=", r["commit_full"]],
                        capture_output=True, text=True, timeout=30
                    ).stdout
                    existe = "SI" if r["archivo_principal"] in res else "NO"
                except Exception:
                    existe = "ERROR"
            veredicto = "COHERENTE" if existe == "SI" else "REVISAR"
            w.writerow([
                r["event_id"], r["commit"], r["fecha"], r["tipo_refactoring"],
                r["entity_id"], r["archivo_principal"], r["descripcion"],
                cmd, existe, veredicto,
            ])

    coherentes = sum(1 for r in muestra if r["archivo_principal"] != "NA")
    print(f"Muestra de auditoria: {len(muestra)} eventos -> {audit_csv}")

    # --- Resumen para la bitacora ------------------------------------------
    print("\n--- Top 10 tipos de refactoring ---")
    for tipo, n in tipos.most_common(10):
        print(f"  {n:5d}  ({100*n/len(rows):5.2f}%)  {tipo}")


if __name__ == "__main__":
    main()
