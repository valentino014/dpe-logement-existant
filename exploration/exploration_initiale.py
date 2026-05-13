"""
Script d'exploration des données ADEME DPE Paris 2025.
Sert à justifier les choix de modélisation documentés dans le DECISIONS.md
(notamment les choix de periode_construction vs annee_construction, 
filtre Paris arrondissements, traitement des données NULL).

Usage : python exploration/explore.py
Sortie : exploration/cardinalite.csv
"""
import pandas as pd

# Constante : codes INSEE des 20 arrondissements de Paris
ARRONDISSEMENTS_PARIS = [
    '75101', '75102', '75103', '75104', '75105',
    '75106', '75107', '75108', '75109', '75110',
    '75111', '75112', '75113', '75114', '75115',
    '75116', '75117', '75118', '75119', '75120'
]


def explore(filepath, sample_size=50000):
    df = pd.read_csv(filepath, nrows=sample_size, low_memory=False)
    print("Shape:", df.shape)
    print("\nColonnes:", df.columns.tolist())
    print("\nCardinalité:")
    df.nunique().sort_values().to_csv('exploration/cardinalite.csv')
    print("\nTaux de NULL (%) :")
    with pd.option_context('display.max_rows', None):
        print((df.isnull().sum() / len(df) * 100).sort_values(ascending=False))

    print("\n--- annee_construction (global) ---")
    print(f"Nombre de valeurs distinctes : {df['annee_construction'].nunique()}")
    print(f"Min : {df['annee_construction'].min()}, Max : {df['annee_construction'].max()}")
    print(f"Taux NULL : {df['annee_construction'].isna().mean()*100:.1f}%")

    print("\n--- periode_construction (global) ---")
    print(df['periode_construction'].value_counts(dropna=False))

    # Analyse spécifique Paris intra-muros
    # Important : code_insee_ban doit être en string avec zéros préservés (utilisation du zfill(5))
    df['code_insee_ban'] = df['code_insee_ban'].astype(str).str.zfill(5)
    df_arr = df[df['code_insee_ban'].isin(ARRONDISSEMENTS_PARIS)]
    
    print(f"\n--- Après filtre arrondissements ({len(df_arr)} lignes) ---")
    print(f"NULL annee_construction : {df_arr['annee_construction'].isna().mean()*100:.1f}%")
    print(f"NULL periode_construction : {df_arr['periode_construction'].isna().mean()*100:.1f}%")
    print(f"\nRépartition par arrondissement :")
    print(df_arr['code_insee_ban'].value_counts().sort_index())

    return df


if __name__ == "__main__":
    df = explore("data/dpe03existant.csv")