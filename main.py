from loader import charger_csv
from sqlalchemy import create_engine

FICHIER = "data/dpe03existant.csv"

if __name__ == "__main__":
    dpe = charger_csv(FICHIER)
    engine = create_engine("postgresql://postgres:postgres@localhost:5433/projet1_db")
    # nécessite de créer le schéma avant dans PG : CREATE SCHEMA IF NOT EXISTS raw;
    print(f"Début de l'insertion de {len(dpe)} lignes dans raw.dpe_paris_2025 en cours...")
    # dpe.to_sql("dpe_paris_2025", con=engine, schema='raw', if_exists="replace", index=False, chunksize=10000, method='multi')
    dpe.to_sql("dpe_paris_2025", con=engine, schema='raw', if_exists="replace", index=False, chunksize=1000)
    print("Insertion terminée")
    