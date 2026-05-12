{{ config(materialized='table') }}
-- Grain : 1 ligne = 1 dpe par logement
with initial as (
    SELECT * FROM {{ ref('stg_dpe') }}
),
deduplicated as (
	select
		*,
	row_number() over (
		partition by dpe.adresse_ban, dpe.numero_etage_appartement
		order by dpe.date_reception_dpe desc, numero_dpe desc
	) as rn
	from
		initial dpe
)
select *
from deduplicated where rn = 1