{{ config(materialized='table') }}

with source as (
    select *
    from {{ ref('int_dpe_latest') }}
)
select 
    {{ dbt_utils.generate_surrogate_key(['adresse_ban', 'numero_etage_appartement']) }} as logement_key,
    adresse_ban,
    numero_etage_appartement,
    type_batiment,
    periode_construction,
    annee_construction,
    type_installation_chauffage,
    qualite_isolation_enveloppe,
    qualite_isolation_murs,
    -- Colonne 1 : la valeur de qualité (COALESCE)
    COALESCE(
    qualite_isolation_plancher_haut_comble_amenage,
    qualite_isolation_plancher_haut_comble_perdu,
    qualite_isolation_plancher_haut_toit_terrasse
    ) AS qualite_isolation_partie_haute,

    -- Colonne 2 : le type de partie haute (CASE WHEN)
    CASE
        WHEN qualite_isolation_plancher_haut_comble_amenage IS NOT NULL THEN 'comble_amenage'
        WHEN qualite_isolation_plancher_haut_comble_perdu   IS NOT NULL THEN 'comble_perdu'
        WHEN qualite_isolation_plancher_haut_toit_terrasse  IS NOT NULL THEN 'toit_terrasse'
        ELSE NULL
    END AS type_partie_haute,
    qualite_isolation_plancher_bas,
    qualite_isolation_menuiseries
from source