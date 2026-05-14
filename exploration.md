## Périmètre du dataset

- Source : ADEME - DPE Logements existants (depuis juillet 2021)
- url : https://data.ademe.fr/datasets/dpe03existant
- Filtres appliqués :
  - code_departement_ban = 75 (Paris)
  - date_visite_diagnostiqueur entre 01-01-2025 et 31-12-2025
- Volumes : 
  - ~175 000 lignes après filtre loader Python (département 75, année 2025)
- Date d'extraction : 2026-04-24

## Analyse du dataset
## volumétrie 
- Lignes : 175000 (échantillon)
- Colonnes : 226

### Test d'unicité de la clé candidate
- numero_dpe : UNIQUE
- Confirme le grain "1 ligne par numero_dpe"

### Colonnes à exclure de la modélisation
**Raison : 100% de NULL ou quasi-NULL**
- Toutes les colonnes _generateur_n2 (deuxième générateur, rare)