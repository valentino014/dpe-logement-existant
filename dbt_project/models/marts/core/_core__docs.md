{% docs dim_logement_doc %}
## Dimension `dim_logement`

**Grain** : 1 ligne = 1 logement parisien unique, défini comme la combinaison de 
`adresse_ban + numero_etage_appartement` (cf. décision 3.10).

**Source** : alimentée par `int_dpe_latest` (déduplication du DPE le plus récent par logement).

**Usage métier** :
- **Q1** : croisée avec `fct_dpe` pour calculer la consommation moyenne par `type_batiment` (type de logement ADEME)
- **Q2** : `periode_construction` (`annee_construction` pas utilisée car ADEME a ~56% de null) utilisée pour analyser le lien construction / performance
- **Q4** : colonnes `qualite_isolation_*` pour identifier les parties les moins bien isolées d'un logement

**Transformation notable** : les 3 colonnes ADEME `qualite_isolation_plancher_haut_*` 
(mutuellement exclusives) sont fusionnées en 2 colonnes métier (valeur + type) 
via COALESCE + CASE WHEN (cf. décision 3.12).

**Limites assumées** :
- Pas de prise en compte de la surface dans la clé de logement (faux négatifs sur 
  appartements identiques au même étage et à la même adresse)
- `annee_construction` contient des valeurs aberrantes (< 1700) marquées mais signalées juste pour visuel
{% enddocs %}

{% docs dim_etiquette_doc %}
## Dimension `dim_etiquette`

**Grain** : 1 ligne = 1 étiquette de notation allant de A à G, définie par `lettre`.

**Source** : alimentée par `seed_etiquette`.

**Usage métier** :
- **Q2** : croisée avec dim_logement pour valider le lien entre `lettre` et `periode_construction`
- **Q5** : croisée `lettre` et `nom_arrondissement` (dim_zone)

**Transformation notable** : utilisation de cette dimension pour la gestion des étiquettes dpe et ges via role-play (cf. décision 3.9).
{% enddocs %}

{% docs dim_zone_doc %}
## Dimension `dim_zone`

**Grain** : 1 ligne = 1 zone (arrondissement).

**Source** : alimentée par `int_dpe_latest` (SELECT avec GROUP BY 
sur code_insee_ban pour 1 ligne par arrondissement, cf. décision 3.14).

**Usage métier** :
- **Q5** : croisée avec `fct_dpe` et `dim_etiquette` pour identifier les arrondissements aux moins bonnes notes DPE et GES

**Transformation notable** : il y a des doublons pour `code_postal_ban` (cf. décision 3.14)

**Limites assumées** :
- Je perds le côté canonique de `code_postal_ban` mais pas utile pour le scope de ce projet
{% enddocs %}

{% docs fct_dpe_doc %}
## Fact `fct_dpe`

**Grain** : 1 ligne = 1 diagnostic DPE.

**Source** : alimentée par `int_dpe_latest` (déduplication du DPE le plus récent par logement).

**Usage métier** :
- **Q1** : colonnes `conso_*` vont permettre de faire plusieurs analyses métier de la consommation moyenne
- **Q3** : `emission_ges_5_usages` et `emission_ges_5_usages_par_m2` pour calculer les émissions par type de logement (`dim_logement`)

**Transformation notable** : 
- La jointure entre `dim_etiquette`, `dim_zone` et `dim_logement` a lieu uniquement dans `int_dpe_latest` (cf. décision 3.13)
- Utilisation d'une matérialisation incremental (cf. décision 3.7)

**Limites assumées** :
- Pas de dim_dpe séparée : numero_dpe reste en degenerate dimension dans la fact (cf. 3.1)
- Incremental ajouté pour montrer le pattern, pas pour une utilisation réelle
{% enddocs %}