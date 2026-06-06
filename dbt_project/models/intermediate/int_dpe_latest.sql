{{ config(materialized='table') }}
-- Grain : 1 ligne = adresse + étage
with initial as (
    SELECT 
		numero_dpe,
        date_visite_diagnostiqueur,
        date_fin_validite_dpe,
        date_reception_dpe,
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
        type_batiment,
        periode_construction,
        annee_construction,
        surface_habitable_logement,
        type_installation_chauffage,
        qualite_isolation_enveloppe,
        qualite_isolation_murs,
        qualite_isolation_plancher_bas,
        qualite_isolation_menuiseries,
        code_insee_ban,
        code_postal_ban,
        etiquette_dpe,
        etiquette_ges,
        adresse_ban,
        numero_etage_appartement,
        qualite_isolation_plancher_haut_comble_amenage,
        qualite_isolation_plancher_haut_comble_perdu,
        qualite_isolation_plancher_haut_toit_terrasse 
	FROM {{ ref('stg_dpe') }}
),
deduplicated as (
	select
		*,
		{{ dbt_utils.generate_surrogate_key(['adresse_ban', 'numero_etage_appartement']) }} as logement_key,
		{{ dbt_utils.generate_surrogate_key(['code_insee_ban']) }} as zone_key,
		{{ dbt_utils.generate_surrogate_key(['etiquette_dpe']) }} as etiquette_dpe_key,
		{{ dbt_utils.generate_surrogate_key(['etiquette_ges']) }} as etiquette_ges_key,
		row_number() over (
			partition by dpe.adresse_ban, dpe.numero_etage_appartement
			order by dpe.date_reception_dpe desc, numero_dpe desc
		) as rn
	from
		initial dpe
)
select *
from deduplicated where rn = 1