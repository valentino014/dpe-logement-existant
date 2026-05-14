# DECISIONS — Projet DPE Logements Existants (Paris 2025)

> Document de traçabilité des décisions techniques et de modélisation prises pendant la construction du projet. Chaque décision est défendable oralement en 30 secondes.

---

## 1. Contexte et scope

- **Source** : CSV ADEME, millésime 2025, scope Paris
- **Volume** : 
  - ~175 000 lignes après filtre loader Python (département 75, année 2025)
- **Stack** : PostgreSQL 15 (Docker), dbt Core 1.11.7
- **Livraison** : fin semaine 12

---

## 2. Questions métier (Q1 à Q5)

| # | Question finale | Notes |
|---|---|---|
| Q1 | Quelle est la consommation moyenne par type de logement ? | — |
| Q2 | Y a-t-il un lien entre la note d'un logement et son année de construction ? | Analyse via `periode_construction` (cf. 3.4) |
| Q3 | Quelles sont les émissions de CO2 par type de logement ? | — |
| Q4 | Quelles parties du logement (murs, planchers, menuiseries...) sont les moins bien isolées par type de logement ? | Question initialement formulée sur les "3 matériaux les plus utilisés", reformulée car la liste des matériaux n'existe pas dans le dataset ADEME |
| Q5 | Quels arrondissements ont les moins bonnes notes DPE et GES ? | Question initialement formulée comme "certains quartiers sont-ils défavorisés ?", reformulée car le dataset ADEME ne contient pas de données socio-économiques. Enrichissement futur possible : croiser avec revenu médian INSEE par arrondissement (hors scope Projet 1) |

---

## 3. Décisions de modélisation

### 3.1 Grain de la fact

- 1 ligne dans `fct_dpe` = 1 diagnostic DPE
- Clé primaire : `numero_dpe` en degenerate dimension
- Justification : le diagnostic est l'élément le plus atomique de l'événement à analyser

### 3.2 Dimensions retenues

| Dimension | Grain | Rôle |
|---|---|---|
| `dim_logement` | 1 logement | Caractéristiques physiques du bâti (relation 1-1 avec le diagnostic dans P1) |
| `dim_zone` | 1 arrondissement | Localisation géographique |
| `dim_etiquette` | 1 lettre (A-G) | Role-playing dimension (voir 3.9) |

### 3.3 Granularité géographique (Q5)

- **Choix** : descendre au niveau **arrondissement** (et non commune) pour Paris
- **Justification** : la commune Paris (code INSEE 75056) est une entité unique, inexploitable pour comparer des "quartiers". Les arrondissements (75101 à 75120) offrent 20 zones comparables.
- **Clé naturelle retenue** : `code_insee_ban` (mapping 1-1 avec l'arrondissement, contrairement au code postal qui peut être multiple, ex. 16e = 75016 + 75116)
- Code postal conservé comme attribut secondaire (utilité opérationnelle)
- Lignes avec `code_insee_ban = 75056` (3 sur 50K) : exclues du périmètre analytique au staging

### 3.4 Granularité temporelle (Q2)

- **Choix** : `periode_construction` retenue comme dimension principale d'analyse
- **Justifications** :
  - 0% de NULL contre 56% pour `annee_construction`
  - Buckets calés sur les réglementations thermiques françaises (RT1974, RT2000, RT2005, RT2012, RE2020), directement interprétables métier
  - 10 modalités vs 219 valeurs distinctes : exploitable en visualisation
- `annee_construction` conservée comme attribut secondaire dans `dim_logement` pour cas d'usage de précision (à manipuler avec précaution : valeurs douteuses dès 1500, nombreux NULL)

### 3.5 Périmètre des consommations

- **EF (énergie finale) retenu** pour la lisibilité métier (c'est ce que paie l'occupant)
- **EP (énergie primaire) non incluse** dans le périmètre Projet 1 car non nécessaire aux 5 questions
- À reconsidérer si analyse de l'étiquette DPE officielle (calculée sur EP)

### 3.6 Stratégie SCD

- Pas de snapshot ni de SCD dans le périmètre Projet 1
- **Justifications** :
  1. Source unique = un fichier CSV ADEME daté, pas de réingestion régulière prévue
  2. Périmètre analytique fermé sur l'année 2025, logements Paris
  3. Les questions métier portent sur l'état du parc, pas sur l'évolution des diagnostics
- SCD à reconsidérer si Projet 2 traite de séries temporelles ADEME multi-millésimes

### 3.7 Stratégie de matérialisation

- Tous les modèles en `materialized='table'` dans Projet 1
- **Justification** : source figée, volume maîtrisé (~50K lignes Paris), simplicité prioritaire pour un premier projet dbt
- Migration vers `incremental` à reconsidérer si scope Projet 2 = ingestion régulière

### 3.8 Late-arriving data

- Pas de stratégie de late-arriving data dans le scope semaine 12
- **Justification** : CSV ADEME 2025 figé, ingestion unique, pas de réingestion prévue
- **Si évolution vers chargement mensuel des millésimes ADEME** : ajout de `loaded_at = current_timestamp` au staging (avec `materialized='table'` pour figer le timestamp), puis filtre incremental sur `loaded_at`. Raison : seule date sous contrôle du pipeline, indépendante des dates métier publiées rétroactivement par l'ADEME.

### 3.9 Role-playing dimension sur `dim_etiquette`

- **Choix** : une seule `dim_etiquette` partagée entre l'étiquette DPE et l'étiquette GES, jointe deux fois dans `fct_dpe` via deux FK distinctes et deux alias en requête
- **Justification** : les deux étiquettes partagent le même domaine de valeurs (A-G) et les mêmes attributs (couleur, libellé, ordre, seuils). Créer deux dimensions séparées violerait DRY et créerait deux sources de vérité pour la même nomenclature : si l'ADEME modifie le code couleur du "C", il faudrait le mettre à jour à deux endroits. La role-playing dim est le pattern Kimball standard pour cette situation.
- **Implémentation** : `fct_dpe` contient `etiquette_dpe_key` et `etiquette_ges_key` (deux FK vers la même table). Les requêtes analytiques font deux `LEFT JOIN` aliasés (ex. `dpe_etiq` et `ges_etiq`).

### 3.10 Dédoublonnage des DPE (`int_dpe_latest`)

- **Règle** : un logement = même `adresse_ban` + même `numero_etage_appartement`. On garde le DPE le plus récent.
- **Critère "le plus récent"** : tri sur `date_reception_dpe` desc, tiebreaker `numero_dpe` desc en cas de date identique.
- **Limites assumées** :
  - Deux appartements distincts au même étage et à la même adresse seront fusionnés en 1 (faux négatif — cas rare en immeuble haussmannien type Paris)
  - Pas de prise en compte de la surface dans la clé de partition : choix de simplicité assumé pour Projet 1
- **Pourquoi cette approche** :
  - Pragmatique : aucun identifiant unique de logement n'existe dans le dataset ADEME
  - Réversible : tous les DPE bruts restent disponibles dans `stg_dpe`, seul l'intermediate dédoublonne
  - Adaptable : la règle peut évoluer (ajout de la surface, géocodage fin) selon les besoins métier

### 3.11 Proxy temporel "DPE le plus récent" (`date_reception_dpe`)

- **Choix** : `date_reception_dpe` utilisée comme proxy de la chronologie réelle des diagnostics (à la place de `date_etablissement_dpe`, absente du dataset)
- **Justification** : la date de réception ADEME suit généralement l'ordre d'établissement par le diagnostiqueur — un DPE plus récent ne peut pas être reçu avant un plus ancien dans la pratique courante
- **Risque résiduel assumé** : un DPE établi tardivement et reçu après un autre plus récent (cas marginal). Acceptable au regard du volume traité.

### 3.12 Transformation isolation partie haute

- Les 3 colonnes ADEME `qualite_isolation_plancher_haut_*` (comble aménagé / comble perdu / toit terrasse) sont mutuellement exclusives par logement.
- Choix : fusionner en 2 colonnes dans dim_logement :
  - `qualite_isolation_partie_haute` : la valeur de qualité (COALESCE des 3)
  - `type_partie_haute` : le type de structure ('comble_amenage', 'comble_perdu', 'toit_terrasse')
- Justification : permet d'analyser la qualité d'isolation indépendamment du type, et le type indépendamment de la qualité.
- Cas non couverts : logements sans aucune des 3 valeurs → NULL sur les deux colonnes (assumé)

### 3.13 SK centralisées dans `int_dpe_latest`

- Choix : générer les 4 surrogate keys (logement_key, zone_key, etiquette_dpe_key, etiquette_ges_key) dans `int_dpe_latest` plutôt que dans chaque dim et dans la fact par après.
- Justification :
  - DRY : un seul endroit où la composition des clés est définie
  - Si la définition métier d'un logement change (ex : ajout de la surface dans le hash), modification à un seul endroit
  - Les dims et la fact consomment les SK déjà calculées via SELECT direct (pas de re-hash)
- Trade-off assumé : `int_dpe_latest` devient "fact-aware" (connait la structure des dims). C'est moins orthodoxe que la convention Kimball stricte (SK générée dans chaque dim) mais le résultat est identique et le code plus court.

### 3.14 Gestion du doublon de code_postal_ban dans dim_zone

- Constat : un même `code_insee_ban` peut avoir plusieurs `code_postal_ban` (ex. 16e arrondissement, INSEE 75116 → codes postaux 75016 ou 75116).
- Choix : `GROUP BY code_insee_ban` + `MAX(code_postal_ban)` pour garantir 1 ligne par arrondissement seulement.
- Justification : `code_postal_ban` est un attribut secondaire, pas besoin d'exhaustivité. `MAX` est arbitraire mais déterministe.
- Limite assumée : le code postal affiché peut ne pas être le plus "canonique" (75016 vs 75116) mais cela est suffisant.

---

## 4. Décisions techniques

### 4.1 Convention de nommage des colonnes

- **Choix Projet 1** : conserver les noms de colonnes ADEME tels quels dans tout le pipeline (staging, intermediate, marts), y compris les suffixes techniques `_ban` (Base Adresse Nationale)
- **Justifications** :
  - Traçabilité maximale entre source et marts pour un projet d'apprentissage
  - Évite la double-cohérence à maintenir entre noms source et noms métier
  - Les colonnes calculées qui n'existent pas dans la source (ex. `nom_arrondissement`, `qualite_isolation_partie_haute`) ont des noms métier explicites
- **À reconsidérer en Projet 2 ou 3** : le standard dbt en environnement multi-sources est de renommer en marts pour un vocabulaire métier unifié. Cette pratique sera mise en œuvre quand le pipeline de base sera maîtrisé.

### 4.2 Syntaxe de cast : long form vs shorthand

- **Choix** : utiliser `cast(x as type)` (forme longue ANSI SQL) plutôt que `x::type` (shorthand PostgreSQL)
- **Justification** : la forme longue est SQL standard ANSI, portable sur PostgreSQL, BigQuery, Snowflake, DuckDB, SQL Server, Oracle. Le shorthand `::` est spécifique à PostgreSQL et n'est pas porté sur BigQuery ni SQL Server.
- Si le projet est porté plus tard sur un autre warehouse, aucun cast à réécrire.
- Coût en lisibilité (syntaxe un peu plus verbeuse) considéré comme négligeable face au gain en portabilité.

### 4.3 Tests

- `unique` + `not_null` sur la PK de chaque modèle staging et modèle modélisé
- `accepted_values` sur `etiquette_dpe` et `etiquette_ges` (A à G), précédé d'une normalisation `upper(trim())` en staging pour protéger contre la donnée sale (espaces parasites, casse)
- `relationships` sur les FK de la fact (à ajouter quand les marts seront créés cette semaine)

### 4.4 Traitement des cas particuliers

- `code_insee_ban = 75056` (3 lignes Paris commune) : exclues du périmètre analytique au staging (filtre `where code_insee_ban in (...)` listant uniquement les 20 arrondissements)
- `annee_construction` avec valeurs douteuses (< 1700 par exemple) : conservées comme attribut secondaire dans `dim_logement` mais flagguées, jamais utilisées comme dimension principale (cf. 3.4)

---

## 5. Dette technique assumée (à traiter cette semaine ou reportée)

| Item | Échéance | Statut |
|---|---|---|
| Marts complets (`fct_dpe`, `dim_logement`, `dim_zone`, `dim_etiquette`) | Sem 12 | En cours (J66-J67) |
| Tests `relationships` sur FK de `fct_dpe` | Sem 12 | À faire après création des marts |
| Documentation détaillée (doc blocks) | Sem 12 | Prévu J68 |
| `dbt-expectations` : exploration et 3-4 tests avancés | Sem 12 (joker possible) | Reporté à sem 13 si débordement (cf. plan joker) |
| README recruteur avec diagramme d'architecture | Sem 12 | Prévu J68-J69 |