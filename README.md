# DPE Logements existants — Analytics dbt

Projet dbt en cours de construction sur le Diagnostic de Performance Énergétique des logements existants sur l'année 2025 à Paris.

Le DPE est au cœur de l'actualité française afin de réduire les émissions de CO2 et la consommation d'énergie en France. 

**Source** : https://data.ademe.fr/datasets/dpe03existant.

## Statut

En exploration. Modélisation prévue à partir du 2026-04-27 (semaine 10 de formation).
Voir `exploration.md` pour les notes en cours.

## Stack

- Python 3.10.12(pandas, sqlalchemy, psycopg2-binary)
- dbt Core 1.11.7
- PostgreSQL 15 (Docker)

## Structure du projet

- `data/`                  Données brutes téléchargées (CSV de ADEME)
- `dbt_project/`           Projet dbt (vide, à construire en sem 10-12)
- `exploration.md`         Notes d'exploration du dataset
- `loader.py`              Lecture du CSV local téléchargé manuellement depuis ADEME
- `main.py`                Point d'entrée du pipeline d'ingestion
- `docker-compose.yml`     PostgreSQL local
- `requirements.txt`       Dépendances Python

## Installation

1. Cloner le repo
```bash
git clone https://github.com/valentino014/dpe-logement-existant.git
```

2. Installer les dépendances:
```bash
pip install -r requirements.txt
```

3. Télécharger le CSV depuis ADEME :
   - Aller sur https://data.ademe.fr/datasets/dpe03existant
   - Ouvrir la vue tabulaire
   - Appliquer les filtres : `code_departement_ban = 75`, `date_visite_diagnostiqueur` entre `2025-01-01` et `2025-12-31`
   - Exporter en CSV et placer le fichier dans `data/dpe03existant.csv`

4. Lancer PostgreSQL:
```bash
docker compose up -d
```

5. Ouvrir postgreSQL en ligne de commande :
```bash
Cocker exec -it projet1_postgres psql -U postgres -d projet1_db
```

6. Créer le schéma dans PostgreSQL :
```bash
CREATE SCHEMA IF NOT EXISTS public;
```

7. Lancer python:
```bash
python3 main.py
```

## Tests

Tests dbt à venir (semaine 11-12) 

## Ce que j'ai appris

- Mise en place de PostgreSQL isolé via Docker Compose (port 5433 pour éviter des conflits avec un autre projet)
- Ingestion d'un CSV valumineux (175k lignes et 254 colonnes) à l'aide de pandas et chunksize pour gérer la mémoire
- Structuration d'un projet dbt séparant données brutes (`raw.*`) et modélisation prochainement

