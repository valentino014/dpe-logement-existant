{{ config(materialized='table') }}

with latest_dpe as (
    --MA VERSION select * from {{ ref('int_dpe_latest') }}
    select distinct
        code_insee_ban,
        max(code_postal_ban) as code_postal_ban 
    from {{ ref('int_dpe_latest') }}
    where code_insee_ban is not null
        and code_insee_ban between '75101' and '75120'
    group by code_insee_ban
)
select
    {{ dbt_utils.generate_surrogate_key(['code_insee_ban']) }} as zone_key,
    code_postal_ban,
    code_insee_ban,
    case code_insee_ban 
        when '75101' then 'Paris 1er'
        when '75102' then 'Paris 2e'
        when '75103' then 'Paris 3e'
        when '75104' then 'Paris 4e'
        when '75105' then 'Paris 5e'
        when '75106' then 'Paris 6e'
        when '75107' then 'Paris 7e'
        when '75108' then 'Paris 8e'
        when '75109' then 'Paris 9e'
        when '75110' then 'Paris 10e'
        when '75111' then 'Paris 11e'
        when '75112' then 'Paris 12e'
        when '75113' then 'Paris 13e'
        when '75114' then 'Paris 14e'
        when '75115' then 'Paris 15e'
        when '75116' then 'Paris 16e'
        when '75117' then 'Paris 17e'
        when '75118' then 'Paris 18e'
        when '75119' then 'Paris 19e'
        when '75120' then 'Paris 20e'
    end as nom_arrondissement     
from latest_dpe