{{ 
    config(materialized='incremental', 
    unique_key='numero_dpe',
    incremental_strategy='merge'
) }}

select 
    numero_dpe,
    date_visite_diagnostiqueur,
    dpe_latest.date_reception_dpe,
    date_fin_validite_dpe,
    modele_dpe,
    version_dpe,
    methode_application_dpe,
    conso_chauffage_ef,
    conso_ecs_ef,
    conso_refroidissement_ef,
    conso_eclairage_ef,
    conso_auxiliaires_ef,
    conso_5_usages_ef,
    conso_5_usages_par_m2_ef,
    emission_ges_5_usages,
    emission_ges_5_usages_par_m2,
    dpe_latest.logement_key,
    dpe_latest.zone_key,
    dpe_latest.etiquette_dpe_key,
    dpe_latest.etiquette_ges_key
from {{ ref('int_dpe_latest') }} as dpe_latest

-- NE PAS SUPPRIMER : filtre incremental, garantit l'idempotence du modèle
{% if is_incremental() %}
    where date_reception_dpe > (select coalesce(max(date_reception_dpe), '1900-01-01') from {{ this }})
{% endif %}