create database energy;
use energy;

-- 1. Country Table
create table if not exists country(
cid varchar(10) primary key,
country varchar(100) unique);

-- 2. Emission_3 Table
create table emission(
country varchar(100),
energy_type varchar(100),
year int,
emission int,
per_capita_emission double,
foreign key(country) references country(country));

-- 3. Population table
create table population(
country varchar(100),
year int,
value double,
foreign key(country) references country(country));

-- 4. Production table
create table production(
country varchar(100),
energy varchar(100),
year int,
production int,
foreign key(country) references country(country));

-- 5. gdp_3 table
create table gdp(
country varchar(100),
year int,
value double,
foreign key(country) references country(country));

-- 6. Consumption table
create table consumption(
country varchar(100),
energy varchar(100),
year int,
consumption int,
foreign key(country) references country(country));

select count(*) from country;
select count(*) from emission;
select count(*) from population;
select count(*) from production;
select count(*) from gdp;
select count(*) from consumption;

## General & Comparative Analysis
-- 1. What is the total emission per country for the most recent year available? 

SELECT country,max(year),SUM(emission) AS total_emission
FROM emission
WHERE year = (SELECT MAX(year) FROM emission)
GROUP BY country, year
ORDER BY total_emission DESC;

-- 2. What are the top 5 countries by GDP in the most recent year?    *****

SELECT country, sum(value) as GDP, year
FROM gdp
WHERE year = (SELECT MAX(year) FROM gdp)
GROUP BY country, year
ORDER BY GDP DESC
LIMIT 5;     

-- 3. Compare energy production and consumption by country and year.
 
SELECT p.country, p.year, sum(p.production) as total_production, sum(c.consumption) as total_consumption
FROM production p
LEFT JOIN consumption c on p.country = c.country AND p.year = c.year
GROUP BY p.country, p.year
ORDER BY p.country, p.year;

-- 4. Which energy types contribute most to emissions across all countries?   ***

select `energy type`, sum(emission) as most_emissions
from emission 
GROUP BY `energy type`
ORDER BY most_emissions desc;

 ## Trend Analysis Over Time
-- 1. How have global emissions changed year over year?   *****

SELECT year, sum(emission) as total_global_emissions
FROM emission
GROUP BY year
ORDER BY year;

-- 2. What is the trend in GDP for each country over the given years?    ***

SELECT year, country, value as GDP
FROM gdp
ORDER BY country, year desc;


-- 3. How has population growth affected total emissions in each country?     ***

SELECT e.country, e.year, sum(e.emission) as total_emission, p.value as population
FROM population p
JOIN emission e on p.countries = e.country AND p.year = e.year
GROUP BY e.country, e.year, p.value
ORDER BY e.country, e.year;

-- 4. Has energy consumption increased or decreased over the years for major economies? ***

SELECT country, year, sum(consumption) as total_consumption
FROM consumption
WHERE country in ('India', 'United States', 'China', 'France', 'Japan')   
GROUP BY country, year
ORDER BY country, year desc;

-- 5. What is the average yearly change in emissions per capita for each country?
SELECT country, avg(`per capita emission`) as avg_per_capita_emission
FROM emission
GROUP BY country
ORDER BY avg_per_capita_emission desc;


## Ratio & Per Capita Analysis
-- 1. What is the emission-to-GDP ratio for each country by year?

SELECT e.country, e.year, sum(e.emission)/ g.value as emission_to_GDP_ratio
FROM emission e
JOIN gdp g on e.country = g.country AND e.year = g.year
GROUP BY e.country, e.year, g.value;

-- 2. What is the energy consumption per capita for each country over the last decade?
SELECT c.country, c.year, sum(c.consumption)/max(p.value) as consumption_per_capita
FROM consumption c
JOIN population p on c.country = p.countries and c.year = p.year
GROUP BY c.country, c.year;

-- 3. How does energy production per capita vary across countries?
SELECT p.country, p.year, sum(p.production) / max(pop.value) as production_per_capita
FROM production p
JOIN population pop on p.country = pop.countries and p.year = pop.year
GROUP BY p.country, p.year
ORDER BY p.country, p.year;

-- 4. Which countries have the highest energy consumption relative to GDP?    

SELECT c.country, sum(c.consumption) / avg(g.value) as consumption_to_gdp_ratio
FROM consumption c
JOIN gdp g on c.country = g.country and c.year = g.year
GROUP BY c.country
ORDER BY consumption_to_gdp_ratio desc;

-- 5. What is the correlation between GDP growth and energy production growth?
SELECT p.country,
round( ((max(g.value) - min(g.value)) / min(g.value)) * 100, 2 ) AS gdp_growth_percent,
round( ((max(p.production) - min(p.production)) / min(p.production)) * 100, 2 ) AS production_growth_percent
FROM production p
JOIN gdp g on p.country = g.country and p.year = g.year
GROUP BY p.country
ORDER BY production_growth_percent asc, gdp_growth_percent desc;


## Global Comparisons

-- 1. What are the top 10 countries by population and how do their emissions compare?
SELECT p.countries, p.value as population, e.emission
FROM population p
JOIN emission e on p.countries = e.country and p.year = e.year         ### Check o/p
WHERE p.year = (SELECT max(year) FROM population)
ORDER BY p.value desc
LIMIT 10;

SELECT 
    p.countries AS Country,
    p.value AS Population,
    e.emission AS Emission
FROM population p
JOIN emission e 
    ON LOWER(TRIM(p.countries)) = LOWER(TRIM(e.country))
    AND p.year = e.year
WHERE p.year = (
    SELECT MIN(p1.year)   -- or MAX(year) if both have same
    FROM population p1
    JOIN emission e1 ON p1.year = e1.year
)
ORDER BY p.value DESC
LIMIT 10;

-- 2. Which countries have improved (reduced) their per capita emissions the most over the last decade?
SELECT country, (max(`per capita emission`) - min(`per capita emission`)) as change_in_per_capita
FROM emission
GROUP BY country
ORDER BY change_in_per_capita;      -- smallest = most reduced           --- Check o/p 

-- 3. What is the global share (%) of emissions by country?

SELECT country, sum(emission) as total_emission,
round(sum(emission) * 100 / (SELECT sum(emission) FROM emission), 2) as percent_share
FROM emission
GROUP BY country
ORDER BY percent_share DESC;

-- 4. What is the global average GDP, emission, and population by year?   ***

SELECT g.year, avg(g.value) as avg_gdp, avg(e.emission) as avg_emission
FROM gdp g
JOIN emission e on g.country = e.country and g.year = e.year
JOIN population p on g.country = p.countries and g.year = p.year
GROUP BY g.year
ORDER BY g.year;

## Ratio & Per Capita Analysis
-- Q 5.
SELECT 
    p.country,
    ROUND(
        CASE 
            WHEN MIN(p.production) IS NULL OR MIN(p.production) = 0 THEN 0
            ELSE ((MAX(p.production) - MIN(p.production)) / MIN(p.production)) * 100
        END, 
    2) AS production_growth_percent,
    
    ROUND(
        CASE 
            WHEN MIN(g.value) IS NULL OR MIN(g.value) = 0 THEN 0
            ELSE ((MAX(g.value) - MIN(g.value)) / MIN(g.value)) * 100
        END,
    2) AS gdp_growth_percent
FROM production p
JOIN gdp g 
ON p.country = g.country 
AND p.year = g.year
GROUP BY p.country
ORDER BY gdp_growth_percent DESC;