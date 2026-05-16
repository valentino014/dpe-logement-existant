# Pitch 3 min — Projet DPE Paris 2025

## Acte 1 — Le problème (30 sec)

Actuellement en France il y a une véritable problématique sur la performance énergétique des logements. Depuis quelques années, plusieurs personnes alertent sur le fait que c'est un sujet qui devrait être au coeur des politiques actuelles. j'ai donc voulu, via ce projet, apporter ma pierre à l'édifice en fournissant un moyen plus simple d'analyser via des requêtes SQL simples les données de l'ADEME.

## Acte 2 — Les données (30 sec)

Sur l'année 2025, à Paris uniquement, ça représentent 175 000 diagnostics. Réduit à 50 000 après filtrage sur les vrais arrondisseemnt parisiens. Les données sont présentés dans ~250 colonnes ce qui ne facilite pas l'analyse des données par des personnes.

## Acte 3 — Ce que j'ai construit (1 min 30)

J'ai donc construit ce projet afin d'aider les analystes à répondre à des questions simples :
- Quelle est la consommation moyenne par type de logement ?
- Y a-t-il un lien entre la note d'un logement et son année de construction ?
- Quelles sont les émissions de CO2 par type de logement ?
- Quelles parties du logement (murs, planchers, menuiseries...) sont les moins bien isolées par type de logement ?
- Quels arrondissements ont les moins bonnes notes DPE et GES ? 

Avec ce projet ils n'auront plus qu'à faire quelques requêtes simple afin de pouvoir répondre aux questions ci-dessus.
Il y aura 3 dimensions. Une zone pour avoir l'arrondissement concerné par le DPE. Une sur le logement afin d'avoir les informations du logement concerné et enfin une sur les étiquettes, soit les notes du diagnostiqueur (DPE et GES). 
Pour finir, une table de fait pour les mesures telles que les consommations du logement ou encore les émissions. 

## Acte 4 — Ce que ça permet (30 sec)

Cela permet au final à des personnes de pouvoir utiliser ces données afin de prendre des décisions plus éclairées dans le domaine de la rénovation énergétique. Et au final profiter au plus grand nombre pour lutter contre les passoires thermiques en France. 