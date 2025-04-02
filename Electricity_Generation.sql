/* Changing name of the column "Data" to "Capacity"*/
ALTER TABLE `electricity-capacity-dataset`
CHANGE COLUMN `Data` `Capacity` varchar(15) not null;

/* Changing name of the column "Source" to "Energy_Source"*/
ALTER TABLE `electricity-capacity-dataset`
CHANGE COLUMN `source` `energy_source` varchar(15) not null;

/* Find total energy genaretion by year and province */
SELECT year, region, SUM(capacity) AS total_capacity
FROM `electricity-capacity-dataset`
WHERE region <> 'Canada'
GROUP BY year, region
ORDER BY year;


/*Total energy generation in Canada by year*/
SELECT year, SUM(capacity) AS total_capacity
FROM `electricity-capacity-dataset`
WHERE region = 'Canada' 
GROUP BY year
ORDER BY year;

/* Total Energy Production by Year and Source in Canada */
SELECT  year, energy_source, SUM(capacity) AS total_capacity
FROM `electricity-capacity-dataset`
WHERE region <> 'Canada'
GROUP BY  year, energy_source
ORDER BY year, total_capacity DESC;

/* Trend of a Specific Energy Source Over Time */
SELECT year, capacity
FROM `electricity-capacity-dataset`
WHERE region = 'BC' AND energy_source = 'Hydro'
ORDER BY year;

/*Which Region Produces the Most Energy in a Specific Year*/
SELECT region, SUM(capacity) AS total_capacity
FROM`electricity-capacity-dataset`
WHERE year = 2016 AND region <> 'Canada'
GROUP BY region
ORDER BY total_capacity DESC;

/* Compare Energy Production Growth Over Time*/
SELECT year, 
       SUM(capacity) AS total_capacity,
       LAG(SUM(capacity)) OVER (ORDER BY year) AS previous_year_capacity,
       SUM(capacity) - LAG(SUM(capacity)) OVER (ORDER BY year) AS capacity_change
FROM `electricity-capacity-dataset`
GROUP BY year
ORDER BY year;

/*The Most Used Energy Source Each Year*/
SELECT year, energy_source, SUM(capacity) AS total_capacity
FROM `electricity-capacity-dataset`
GROUP BY year, energy_source
HAVING SUM(capacity) = (
    SELECT MAX(total_capacity)
    FROM (
        SELECT year, energy_source, SUM(capacity) AS total_capacity
        FROM `electricity-capacity-dataset`
        GROUP BY year, energy_source
    ) AS subquery WHERE subquery.year = `electricity-capacity-dataset`.year
)
ORDER BY year;

/*Compare Renewable vs Non-Renewable Energy Production */
SELECT year,
       SUM(CASE WHEN energy_source IN ('Hydro', 'Wind', 'Solar', 'Biomass') THEN capacity ELSE 0 END) AS renewable_capacity,
       SUM(CASE WHEN energy_source IN ('Nuclear', 'Coal', 'Natural Gas', 'Oil and Diesel') THEN capacity ELSE 0 END) AS non_renewable_capacity
FROM `electricity-capacity-dataset`
GROUP BY year
ORDER BY year;

/* The Fastest-Growing Energy Source */
WITH yearly_totals AS (
    SELECT 
        energy_source, 
        year, 
        SUM(capacity) AS yearly_capacity
    FROM `electricity-capacity-dataset`
    GROUP BY energy_source, year
),
growth_calc AS (
    SELECT 
        energy_source, 
        year, 
        yearly_capacity,
        LAG(yearly_capacity) OVER (PARTITION BY energy_source ORDER BY year) AS previous_year_capacity,
        ((yearly_capacity - LAG(yearly_capacity) OVER (PARTITION BY energy_source ORDER BY year)) 
         / NULLIF(LAG(yearly_capacity) OVER (PARTITION BY energy_source ORDER BY year), 0)) * 100 AS growth_percentage
    FROM yearly_totals
)
SELECT energy_source, AVG(growth_percentage) AS avg_growth_rate
FROM growth_calc
WHERE growth_percentage IS NOT NULL
GROUP BY energy_source
ORDER BY avg_growth_rate DESC
LIMIT 1;
