{{ config(materialized='table') }}
with cleaned as (
    select 
        cast(numero_dpe as text) as numero_dpe,
        cast(date_visite_diagnostiqueur as date) as date_visite_diagnostiqueur,
        cast(date_fin_validite_dpe as date) as date_fin_validite_dpe,
        cast(date_reception_dpe as date) as date_reception_dpe,
        cast(modele_dpe as text) as modele_dpe,
        cast(version_dpe as text) as version_dpe,
        cast(methode_application_dpe as text) as methode_application_dpe,
        cast(conso_chauffage_ef as numeric(10, 2)) as conso_chauffage_ef,
        cast(conso_ecs_ef as numeric(10, 2)) as conso_ecs_ef,
        cast(conso_refroidissement_ef as numeric(10, 2)) as conso_refroidissement_ef,
        cast(conso_eclairage_ef as numeric(10, 2)) as conso_eclairage_ef,
        cast(conso_auxiliaires_ef as numeric(10, 2)) as conso_auxiliaires_ef,
        cast("conso_5 usages_ef" as numeric(12, 2)) as conso_5_usages_ef,
        cast("conso_5 usages_par_m2_ef" as numeric(10, 2)) as conso_5_usages_par_m2_ef,
        cast(emission_ges_5_usages as numeric(12, 2)) as emission_ges_5_usages,
        cast("emission_ges_5_usages par_m2" as numeric(10, 2)) as emission_ges_5_usages_par_m2,
        cast(type_batiment as text) as type_batiment,
        cast(periode_construction as text) as periode_construction,
        cast(annee_construction as int) as annee_construction,
        cast(surface_habitable_logement as numeric(10, 2)) as surface_habitable_logement,
        cast(type_installation_chauffage as text) as type_installation_chauffage,
        cast(qualite_isolation_enveloppe as text) as qualite_isolation_enveloppe,
        cast(qualite_isolation_murs as text) as qualite_isolation_murs,
        cast("qualite_isolation_plancher bas" as text) as qualite_isolation_plancher_bas,
        cast(qualite_isolation_menuiseries as text) as qualite_isolation_menuiseries,
        cast(code_insee_ban as text) as code_insee_ban,
        lpad(cast(code_postal_ban as text), 5, '0') as code_postal_ban,
        upper(trim(etiquette_dpe)) as etiquette_dpe,
        upper(trim(etiquette_ges)) as etiquette_ges,
        cast(adresse_ban as text) as adresse_ban,
        cast(numero_etage_appartement as text) as numero_etage_appartement
    from {{ source('ademe', 'dpe_paris_2025') }}
    -- Filtre Paris arrondissements (exclut 75056 = Paris commune, hors scope analytique)
    where code_insee_ban in (
        '75101','75102','75103','75104','75105','75106','75107','75108','75109','75110',
        '75111','75112','75113','75114','75115','75116','75117','75118','75119','75120'
    )
)
select * from cleaned