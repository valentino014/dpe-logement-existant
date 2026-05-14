{{ config(materialized='table') }}
-- Grain : 1 ligne = 1 dpe par logement
with initial as (
    SELECT * FROM {{ ref('stg_dpe') }}
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