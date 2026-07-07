CREATE DATABASE happiness_unemployment;
USE happiness_unemployment;

-- whi_inflation.csv had some NULL values so to keep them as NULL I first imported them as strings and then converted them to DECIMAL
-- The same was done for global unemployment.csv for precaution

CREATE TABLE global_unemployment_stage (
    iso_code VARCHAR(10),
    country VARCHAR(100),
    sex VARCHAR(10),
    age VARCHAR(20),
    year INT,
    unemployment_rate DECIMAL(8,3)
    );

    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/global unemployment.csv'
INTO TABLE global_unemployment_stage
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE global_unemployment_clean AS
SELECT
    iso_code,
    TRIM(country) AS country,
    TRIM(sex) AS sex,
    TRIM(age) AS age,
    year,
    unemployment_rate
FROM global_unemployment_stage
WHERE year BETWEEN 2015 AND 2023
;

-- cpi stands for consumer price inflation

-- Some economic indicators contain empty strings and returned an error when trying to import into DECIMAL columns.
-- To preserve the integrity of the raw data I first imported the raw data in VARCHAR columns,
-- turned empty strings into NULLs and finally converted everything into DECIMAL

CREATE TABLE whi_inflation_stage (
    country VARCHAR(100),
    year INT,
    headline_cpi VARCHAR(50),
    energy_cpi VARCHAR(50),
    food_cpi VARCHAR(50),
    official_core_cpi VARCHAR(50),
    producer_price_inflation VARCHAR(50),
    gdp_deflator_rate VARCHAR(50),
    continent_region VARCHAR(100),
    happiness_score VARCHAR(50),
    gdp_per_capita VARCHAR(50),
    social_support VARCHAR(50),
    life_expectancy VARCHAR(50),
    freedom_choices VARCHAR(50),
    generosity VARCHAR(50),
    corruption_perceptions VARCHAR(50)
);
    
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/whi_inflation.csv'
INTO TABLE whi_inflation_stage
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE whi_inflation_clean AS
SELECT
    TRIM(country) AS country,
    year,
    CAST(NULLIF(headline_cpi,'') AS DECIMAL(20,10)) AS headline_cpi,
    CAST(NULLIF(energy_cpi,'') AS DECIMAL(20,10)) AS energy_cpi,
    CAST(NULLIF(food_cpi,'') AS DECIMAL(20,10)) AS food_cpi,
	CAST(NULLIF(official_core_cpi,'') AS  DECIMAL(20,10)) AS official_core_cpi,
	CAST(NULLIF(producer_price_inflation,'') AS DECIMAL(20,10)) AS producer_price_inflation,
    CAST(NULLIF(gdp_deflator_rate,'') AS DECIMAL(20,10)) AS gdp_deflator_rate,
    TRIM(continent_region) AS continent_region,
    CAST(NULLIF(happiness_score,'') AS DECIMAL(6,3)) AS happiness_score,
    CAST(NULLIF(gdp_per_capita,'') AS DECIMAL(18,6)) AS gdp_per_capita,
    CAST(NULLIF(social_support,'') AS DECIMAL(6,4)) AS social_support,
    CAST(NULLIF(life_expectancy,'') AS DECIMAL(6,4)) AS life_expectancy,
    CAST(NULLIF(freedom_choices,'') AS DECIMAL(6,4)) AS freedom_choices,
    CAST(NULLIF(generosity,'') AS DECIMAL(6,4)) AS generosity,
    CAST(NULLIF(corruption_perceptions,'') AS DECIMAL(6,4)) AS corruption_perceptions
FROM whi_inflation_stage
;  

-- Counting how many records each table has
    
SELECT COUNT(*)
FROM global_unemployment_clean;

SELECT COUNT(*)
FROM whi_inflation_clean;
   
-- Counting how many missing values each column has of each table has

SELECT
    SUM(country IS NULL) AS missing_country,
    SUM(year IS NULL) AS missing_year,
    SUM(headline_cpi IS NULL) AS missing_headline_cpi,
    SUM(energy_cpi IS NULL) AS missing_energy_cpi,
    SUM(food_cpi IS NULL) AS missing_food_cpi,
    SUM(official_core_cpi IS NULL) AS missing_core_cpi,
    SUM(producer_price_inflation IS NULL) AS missing_ppi,
    SUM(gdp_deflator_rate IS NULL) AS missing_gdp_deflator,
    SUM(score IS NULL) AS missing_happiness,
    SUM(gdp_per_capita IS NULL) AS missing_gdp,
    SUM(social_support IS NULL) AS missing_social_support,
    SUM(life_expectancy IS NULL) AS missing_life_expectancy,
    SUM(freedom_choices IS NULL) AS missing_freedom,
    SUM(generosity IS NULL) AS missing_generosity,
    SUM(corruption_perceptions IS NULL) AS missing_corruption
FROM whi_inflation_clean;

SELECT
    SUM(iso_code IS NULL) AS missing_iso_code,
    SUM(country IS NULL) AS missing_country,
    SUM(sex IS NULL) AS missing_sex,
    SUM(age IS NULL) AS missing_age,
    SUM(year IS NULL) AS missing_year,
    SUM(unemployment_rate IS NULL) AS missing_unemployment_rate
FROM global_unemployment_clean;

-- Checking for duplicates

SELECT
    country,
    year,
    sex,
    age,
    COUNT(*) AS duplicates
FROM global_unemployment_clean
GROUP BY
    country,
    year,
    sex,
    age
HAVING COUNT(*) > 1;

SELECT year, country, COUNT(*) AS duplicates
FROM whi_inflation_clean
GROUP BY year, country
HAVING COUNT(*)>1;

-- Identifying how many countries match and how many don't, with a side by side comparison to get an idea of how much correction is necessary 

SELECT DISTINCT country
FROM global_unemployment_clean
ORDER BY country;

SELECT DISTINCT country
FROM whi_inflation_clean
ORDER BY country;

-- whi_inflation_clean is the table the analysis will be based on so we only want to include countries in global_unemployment_clean that are present in the first table

SELECT DISTINCT w.country
FROM whi_inflation_clean w
LEFT JOIN global_unemployment_clean g
    ON w.country = g.country
WHERE g.country IS NULL
ORDER BY w.country;

-- It is important to make sure that these countries are acutally absent instead of just being written differently
-- These are the countries that have different names in global_unemployment_clean: Bolivia, Czech Republic, Moldova, Swaizland(Eswatini), Taiwan,Tanzania, Turkey, United Kingdom, United States, Vietnam
-- The countries that are present in whi_inflation_clean but absent in global_unemployment_clean are Kosovo, Puerto Rico,

UPDATE whi_inflation_clean
SET country = 'Eswatini'
WHERE country LIKE 'Swaziland';

UPDATE global_unemployment_clean
SET country = 'Bolivia'
WHERE country LIKE 'Bolivia (Plurinational State of)';

UPDATE global_unemployment_clean
SET country = 'Bolivia'
WHERE country LIKE 'Bolivia';

UPDATE global_unemployment_clean
SET country = 'Czech Republic'
WHERE country LIKE 'Czechia';

UPDATE global_unemployment_clean
SET country = 'Moldova'
WHERE country LIKE 'Republic of Moldova';
 
UPDATE whi_inflation_clean
SET country = 'Taiwan'
WHERE country LIKE 'Taiwan Province of China';

UPDATE global_unemployment_clean
SET country = 'Taiwan'
WHERE country LIKE 'Taiwan, China';

UPDATE global_unemployment_clean
SET country = 'Tanzania'
WHERE country LIKE 'Tanzania, United Republic of';

UPDATE global_unemployment_clean
SET country = 'United Kingdom'
WHERE country LIKE 'United Kingdom of Great Britain and Northern Ireland';

UPDATE global_unemployment_clean
SET country = 'United States'
WHERE country LIKE 'United States of America';

UPDATE global_unemployment_clean
SET country = 'Vietnam'
WHERE country LIKE 'Viet Nam';

UPDATE global_unemployment_clean
SET country = 'Turkey'
WHERE country LIKE 'Türkiye';

SELECT
MIN(unemployment_rate),
MAX(unemployment_rate)
FROM global_unemployment_clean;

SELECT
MIN(happiness_score),
MAX(happiness_score)
FROM whi_inflation_clean;

SELECT
MIN(gdp_per_capita),
MAX(gdp_per_capita)
FROM whi_inflation_clean;

SELECT
MIN(headline_cpi),
MAX(headline_cpi)
FROM whi_inflation_clean;

SELECT DISTINCT year
FROM global_unemployment_clean
ORDER BY year;

SELECT DISTINCT year
FROM whi_inflation_clean
ORDER BY year;

-- Data Quality Summary --

-- Checked for duplicates and none was found,
-- There is no missing value in any key field,
-- all relevant country names have been standardised and numeric ranges have been checked to spot any unrealistic value or outlier

-- The ETL process is now complete and the data is now ready for the EDA process
-- How have inflation and unemployment influenced national well-being across countries between 2015 and 2023?

-- First I joined the two tables because some of the variables are only available in one table.
-- Using an inner join also allows to filter for everyone aged 15 and older and every sex.

CREATE VIEW joined_data AS
SELECT 
    w.country,
    w.year,
    w.happiness_score,
    w.headline_cpi AS inflation_rate,
    g.unemployment_rate
FROM whi_inflation_clean w
JOIN global_unemployment_clean g
  ON w.country = g.country
  AND w.year = g.year
WHERE sex ='Total'
AND age = '15+';

SELECT *
FROM joined_data;