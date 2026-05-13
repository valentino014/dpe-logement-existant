{{ config(materialized='table')}}

with seed as(
    select 
        lettre,
        libelle,
        couleur_hex,
        ordre_classement 
    from {{ ref('seed_etiquette') }}
)
select 
    {{ dbt_utils.generate_surrogate_key(['lettre']) }} as etiquette_key,
    lettre,
    libelle,
    couleur_hex,
    ordre_classement 
from seed