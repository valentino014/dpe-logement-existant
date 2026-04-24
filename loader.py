import pandas as pd

def charger_csv(chemin):
    try:
        df = pd.read_csv(chemin, low_memory=False)
        print(df.shape)
        return df
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier : {chemin}")
        print()
        print(e)
        return None

