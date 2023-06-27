-- This project aims to create a comprehensive, current snapshot of COVID-19 cases within the state of CA as a Tableau dashboard.  Publicly available datasets
-- obtained from CA State Department of Public Health and CA State Department of Finance were utilized for this analysis, with the dataset cleaning and transformation
-- process done using T-SQL/MSSQL.  Please see below for the documentation of this process.


-- For all COVID-19 CA datasets obtained from CA State Department of Public Health, the total rows and top 5 rows per dataset were 
-- checked against original sources and verified for data table creation integrity. 

-- Since the CA county populations dataset (P-3 Race/Ethnicity and Sex By Age for California and Counties) obtained from CA State Department of Finance underwent initial 
-- importing, cleaning, and transformation using Power Query, summations of county populations for 2020 from the data table were cross verified against another dataset provided 
-- by the department, P-2A Total Population for California and Counties.  The total rows and top 5 rows were checked against original source as well for data table creation integrity.

-- Population columns provided on the datasets from CA Department of Public Health were not utilized for this analysis since there were slight discrepancies found between their values and
-- and their stated original data source, 2020 population projections by CA State Department of Finance.  Original data source from CA State Department of Finance will be used for 
-- this analysis.    


-- COVID19 Variants: To assess variants and their monthly distributions, need to perform a summation of sequenced specimens and group by variant_name, month, year for California.  
-- Saved output as new .csv file, covid19_variants_aggregation.  

SELECT
    variant_name,
    SUM(specimens) AS 'specimens',
    MONTH(date) AS 'month',
    YEAR(date) AS 'year'
FROM covid19_variants
WHERE area='California' AND area_type='state' AND variant_name!='Total'
GROUP BY variant_name, MONTH(date), YEAR(date)
ORDER BY YEAR(date), MONTH(date)

-- Verifying above query by checking all variant names and comparing summation of variant types against summation of 'Total' reported under variant_name.

SELECT DISTINCT(variant_name) FROM covid19_variants

SELECT
    variant_name,
    SUM(specimens) AS 'provided_totals_specimens',
    MONTH(date) AS 'month',
    YEAR(date) AS 'year'
FROM covid19_variants
WHERE area='California' AND area_type='state' AND variant_name='Total'
GROUP BY variant_name, MONTH(date), YEAR(date)
ORDER BY YEAR(date), MONTH(date)

SELECT
    SUM(specimens) AS 'total_specimens',
    MONTH(date) AS 'month',
    YEAR(date) AS 'year'
FROM covid19_variants
WHERE area='California' AND area_type='state' AND variant_name!='Total'
GROUP BY MONTH(date), YEAR(date)
ORDER BY YEAR(date), MONTH(date)

-- Checking for NULL values in original dataset, covid19_variants.
-- This only returned NULLs for 7d_avgs, which are not needed for analysis.
-- Total of 60 rows affected (8700 rows in original dataset).  No additional further cleaning and transformation needed.

SELECT * FROM covid19_variants
WHERE 
    date IS NULL OR 
    area IS NULL OR 
    area_type IS NULL OR
    variant_name IS NULL OR
    specimens IS NULL OR
    percentage IS NULL OR
    specimens_7d_avg IS NULL OR
    percentage_7d_avg IS NULL

-- Checking for duplicate records in original dataset, covid19_variants. No duplicate records found.

SELECT date, variant_name, COUNT(*) AS duplicate_records
FROM covid19_variants
GROUP BY date, variant_name
HAVING COUNT(*) > 1


-- CA Vaccinations By County: To assess the current cumulative vaccinations performed within all CA counties and their percentages against CA county populations, 
-- need to merge county population values from another dataset and select latest records for cumulative reported values.
-- Saved output as new .csv file, covid19_current_totals_vaccinations_county.  

WITH CTE_county_populations AS
    (SELECT area, SUM(population_2020) AS county_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY area)

SELECT
    vc.county,
    vc.administered_date AS last_reporting_date,
    vc.cumulative_total_doses,
    vc.total_partially_vaccinated,
    vc.cumulative_fully_vaccinated,
    vc.cumulative_at_least_one_dose,
    vc.cumulative_booster_recip_count,
    vc.cumulative_bivalent_booster_recip_count,
    cp.county_population_2020,
    (SELECT SUM(population_2020) FROM p3_california_and_counties_v2) AS total_state_population_2020
FROM covid19_vaccines_by_county vc
LEFT JOIN CTE_county_populations cp ON vc.county = cp.area
WHERE vc.administered_date=
    (SELECT MAX(vc2.administered_date)
    FROM covid19_vaccines_by_county vc2
    WHERE vc2.county = vc.county)
ORDER BY vc.county ASC

-- Verifying data join by comparing output to what was expected.  

SELECT DISTINCT area, SUM(population_2020) AS county_population_2020
FROM p3_california_and_counties_v2
GROUP BY area
ORDER BY area ASC

-- Checking for NULL values in original dataset, covid19_vaccines_by_county.  Total of 11222 rows affected (64852 rows in original dataset).  
-- This only returned NULL values in column 'california_flag', with 332 affected rows having column 'county' values='Unknown', 'Outside California'.  
-- Those with california_flag='Not in California' have county='Outside California','Unknown'.
-- Column 'california_flag' has three distinct entry types: 'NULL', 'California', 'Not in California'.  
-- Significant portion is likely due to data-entry issue, with many CA county observations having NULL values for california_flag.  
-- Additionally, per the original source data dictionary, 'Non-California and Unknown doses have been included so the total of all entries matches the total reported for California for a particular date.'

SELECT * FROM covid19_vaccines_by_county
WHERE
    county IS NULL OR
    administered_date IS NULL OR
    total_doses IS NULL OR
    cumulative_total_doses IS NULL OR
    pfizer_doses IS NULL OR
    cumulative_pfizer_doses IS NULL OR
    moderna_doses IS NULL OR
    cumulative_moderna_doses IS NULL OR
    jj_doses IS NULL OR
    cumulative_jj_doses IS NULL OR
    partially_vaccinated IS NULL OR
    total_partially_vaccinated IS NULL OR
    fully_vaccinated IS NULL OR
    cumulative_fully_vaccinated IS NULL OR
    at_least_one_dose IS NULL OR
    cumulative_at_least_one_dose IS NULL OR
    california_flag IS NULL OR
    booster_recip_count IS NULL OR
    bivalent_booster_recip_count IS NULL OR
    cumulative_booster_recip_count IS NULL OR
    cumulative_bivalent_booster_recip_count IS NULL

SELECT DISTINCT(california_flag) FROM covid19_vaccines_by_county

SELECT DISTINCT(county) FROM covid19_vaccines_by_county
WHERE california_flag='Not in California'

SELECT * FROM covid19_vaccines_by_county
WHERE california_flag IS NULL AND county IN('Unknown', 'Outside California')

SELECT * FROM covid19_vaccines_by_county
WHERE california_flag IS NULL AND county NOT IN ('Unknown', 'Outside California')

-- Checking for duplicate records in original dataset, covid19_vaccines_by_county. No duplicate records found.

SELECT county, administered_date, COUNT(*) AS duplicate_records
FROM covid19_vaccines_by_county
GROUP BY county, administered_date
HAVING COUNT(*) > 1

-- Columns 'booster_eligible_population' and 'bivalent_booster_eligible_population' will not be used for this analysis.  Comparison against county total populations
-- showed that the values likely reflected older CDC recommendations for COVID-19 booster/bivalent booster eligibility.  Additionally, these values are the same between
-- 'booster' and 'bivalent_booster' columns (bivalent introduced during fall 2022) and have not changed with changing CDC COVID-19 booster recommendations throughout 
-- the time series dataset.

WITH CTE_county_populations AS
    (SELECT area, SUM(population_2020) AS county_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY area)

SELECT DISTINCT vc.county, vc.booster_eligible_population, vc.bivalent_booster_eligible_population, cp.county_population_2020
FROM covid19_vaccines_by_county vc
LEFT JOIN CTE_county_populations cp ON vc.county=cp.area
ORDER BY vc.county ASC

-- Checking for NULL values in original dataset, p3_california_and_counties.  No NULL values were identified in the dataset (total of 0 rows affected, 90132 rows in original dataset).

SELECT * FROM p3_california_and_counties_v2
WHERE
    area IS NULL OR
    area_type IS NULL OR
    sex IS NULL OR
    race_ethnicity_code IS NULL OR
    race_ethnicity IS NULL OR
    age IS NULL OR
    population_2020 IS NULL

-- Checking for duplicate records in original dataset, p3_california_and_counties. No duplicate records found.

SELECT area, sex, race_ethnicity, age, population_2020, COUNT(*) AS duplicate_records
FROM p3_california_and_counties_v2
GROUP BY area, sex, race_ethnicity, age, population_2020
HAVING COUNT(*) > 1


-- CA Vaccinations By Demographics: To assess the current cumulative vaccinations by demographics and their percentages against CA statewide populations,
-- need to merge demographic population values from another dataset and select latest records for cumulative reported values. 

-- Saved output as new .csv file, covid19_current_totals_vaccinations_demographics. 
-- Note that there is a limitation on demographic populations, with population estimates not accounting for 'Other' or 'Unknown' on race/ethnicity.

WITH CTE_demographic_populations AS
    (SELECT
        CASE race_ethnicity 
           WHEN 'White NH' THEN 'White' 
           WHEN 'Black NH' THEN 'Black or African American'
           WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
           WHEN 'Asian NH' THEN 'Asian'
           WHEN 'NHPI NH' THEN 'Native Hawaiian or Other Pacific Islander'
           WHEN 'MR NH' THEN 'Multiracial'
           WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE race_ethnicity 
            WHEN 'White NH' THEN 'White' 
            WHEN 'Black NH' THEN 'Black or African American'
            WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
            WHEN 'Asian NH' THEN 'Asian'
            WHEN 'NHPI NH' THEN 'Native Hawaiian or Other Pacific Islander'
            WHEN 'MR NH' THEN 'Multiracial'
            WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END
    UNION
    SELECT
        sex AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY sex
    UNION
    SELECT
        CASE
            WHEN age <=4 THEN 'Under 5'
            WHEN age BETWEEN 5 AND 11 THEN '5-11'
            WHEN age BETWEEN 12 AND 17 THEN '12-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+' 
        END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE
            WHEN age <=4 THEN 'Under 5'
            WHEN age BETWEEN 5 AND 11 THEN '5-11'
            WHEN age BETWEEN 12 AND 17 THEN '12-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+'
        END)

SELECT
    vd.demographic_category,
    vd.demographic_value,
    vd.administered_date AS last_reporting_date,
    vd.cumulative_total_doses,
    vd.total_partially_vaccinated,
    vd.cumulative_fully_vaccinated,
    vd.cumulative_at_least_one_dose,
    vd.cumulative_booster_recip_count,
    vd.cumulative_bivalent_booster_recip_count,
    dp.demographic_population_2020,
    (SELECT SUM(population_2020) FROM p3_california_and_counties_v2) AS total_state_population_2020
FROM covid19_vaccines_administered_by_demographics vd
LEFT JOIN CTE_demographic_populations dp ON vd.demographic_value=dp.demographic_value
WHERE vd.administered_date=
    (SELECT MAX(vd2.administered_date)
    FROM covid19_vaccines_administered_by_demographics vd2
    WHERE vd2.demographic_value=vd.demographic_value)
ORDER BY vd.demographic_category ASC, vd.demographic_value ASC

-- Verifying distinct demographic values for the two datasets joined in the above query.

SELECT DISTINCT race_ethnicity, race_ethnicity_code FROM p3_california_and_counties_v2

SELECT DISTINCT age FROM p3_california_and_counties_v2
ORDER BY age ASC

SELECT DISTINCT sex FROM p3_california_and_counties_v2

SELECT DISTINCT demographic_category, demographic_value
FROM covid19_vaccines_administered_by_demographics
ORDER BY demographic_category ASC, demographic_value ASC

-- Columns 'booster_eligible_population' and 'bivalent_booster_eligible_population' will not be used for this analysis.  Comparison against county total populations
-- showed that the values likely reflected older CDC recommendations for COVID-19 booster/bivalent booster eligibility.  Additionally, these values are the same between
-- 'booster' and 'bivalent_booster' columns (bivalent introduced during fall 2022) and have not changed with changing CDC COVID-19 booster recommendations throughout the time series dataset.

WITH CTE_demographic_populations AS
    (SELECT
        CASE race_ethnicity 
           WHEN 'White NH' THEN 'White' 
           WHEN 'Black NH' THEN 'Black or African American'
           WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
           WHEN 'Asian NH' THEN 'Asian'
           WHEN 'NHPI NH' THEN 'Native Hawaiian or Other Pacific Islander'
           WHEN 'MR NH' THEN 'Multiracial'
           WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE race_ethnicity 
            WHEN 'White NH' THEN 'White' 
            WHEN 'Black NH' THEN 'Black or African American'
            WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
            WHEN 'Asian NH' THEN 'Asian'
            WHEN 'NHPI NH' THEN 'Native Hawaiian or Other Pacific Islander'
            WHEN 'MR NH' THEN 'Multiracial'
            WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END
    UNION
    SELECT
        sex AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY sex
    UNION
    SELECT
        CASE
            WHEN age <=4 THEN 'Under 5'
            WHEN age BETWEEN 5 AND 11 THEN '5-11'
            WHEN age BETWEEN 12 AND 17 THEN '12-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+' 
        END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE
            WHEN age <=4 THEN 'Under 5'
            WHEN age BETWEEN 5 AND 11 THEN '5-11'
            WHEN age BETWEEN 12 AND 17 THEN '12-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+'
        END)

SELECT DISTINCT vd.demographic_category, vd.demographic_value, vd.booster_eligible_population, vd.bivalent_booster_eligible_population, dp.demographic_population_2020
FROM covid19_vaccines_administered_by_demographics vd
LEFT JOIN CTE_demographic_populations dp ON vd.demographic_value=dp.demographic_value
ORDER BY vd.demographic_category ASC, vd.demographic_value ASC

-- Checking for NULL values in original dataset, covid19_vaccines_administered_by_demographics.  
-- No NULL values were identified in the dataset (total of 0 rows affected, 18360 rows in original dataset).

SELECT * FROM covid19_vaccines_administered_by_demographics
WHERE
    demographic_category IS NULL OR
    demographic_value IS NULL OR
    administered_date IS NULL OR
    total_doses IS NULL OR
    cumulative_total_doses IS NULL OR
    pfizer_doses IS NULL OR
    cumulative_pfizer_doses IS NULL OR
    moderna_doses IS NULL OR
    cumulative_moderna_doses IS NULL OR
    jj_doses IS NULL OR
    cumulative_jj_doses IS NULL OR
    partially_vaccinated IS NULL OR
    total_partially_vaccinated IS NULL OR
    fully_vaccinated IS NULL OR
    cumulative_fully_vaccinated IS NULL OR
    at_least_one_dose IS NULL OR
    cumulative_at_least_one_dose IS NULL OR
    booster_recip_count IS NULL OR
    bivalent_booster_recip_count IS NULL OR
    cumulative_booster_recip_count IS NULL OR
    cumulative_bivalent_booster_recip_count IS NULL OR
    booster_eligible_population IS NULL OR
    bivalent_booster_eligible_population IS NULL

-- Checking for duplicate records in original dataset, covid19_vaccines_administered_by_demographics. No duplicate records found.

SELECT demographic_category, demographic_value, administered_date, COUNT(*) AS duplicate_records
FROM covid19_vaccines_administered_by_demographics
GROUP BY demographic_category, demographic_value, administered_date
HAVING COUNT(*) > 1


-- CA COVID-19 Cases, Deaths, Tests:  To assess COVID-19 cases, deaths, and tests on a state-wide level, two cleaned datasets 
-- need to be generated, one as a time series and the other showing latest records for cumulative reported values.  County population values from another
-- dataset will need to be merged into the time series dataset as well.

-- Checking for NULL values in original dataset, covid19_cases_deaths_tests.
-- Total of 2564 rows affected (74603 rows in original dataset).  2446 rows have area='Out of state','Unknown'. 
-- Remaining NULL values likely preliminary reports with information still pending, based on DISTINCT date values.
-- All observations with NULL values will be removed for time series dataset and cumulative totals dataset.

SELECT * FROM covid19_cases_deaths_tests
WHERE 
    date IS NULL OR 
    area IS NULL OR 
    area_type IS NULL OR
    population IS NULL OR
    cases IS NULL OR
    cumulative_cases IS NULL OR
    deaths IS NULL OR
    cumulative_deaths IS NULL OR
    total_tests IS NULL OR
    cumulative_total_tests IS NULL OR
    positive_tests IS NULL OR
    cumulative_positive_tests IS NULL

SELECT * FROM covid19_cases_deaths_tests
WHERE area IN('Out of state', 'Unknown')

SELECT DISTINCT(cdt.date) 
FROM
    (SELECT * FROM covid19_cases_deaths_tests
    WHERE area NOT IN('Out of state','Unknown')) cdt
WHERE 
    cdt.date IS NULL OR 
    cdt.area IS NULL OR 
    cdt.area_type IS NULL OR
    cdt.population IS NULL OR
    cdt.cases IS NULL OR
    cdt.cumulative_cases IS NULL OR
    cdt.deaths IS NULL OR
    cdt.cumulative_deaths IS NULL OR
    cdt.total_tests IS NULL OR
    cdt.cumulative_total_tests IS NULL OR
    cdt.positive_tests IS NULL OR
    cdt.cumulative_positive_tests IS NULL
ORDER BY cdt.date DESC

-- Saved output as new .csv file, covid19_cases_deaths_tests_timeseries.

WITH CTE_county_populations AS
    (SELECT area, SUM(population_2020) AS county_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY area)

SELECT 
    cdt.date, 
    cdt.area, 
    cdt.area_type, 
    cdt.cases, 
    cdt.cumulative_cases, 
    cdt.deaths, 
    cdt.cumulative_deaths, 
    cdt.total_tests, 
    cdt.cumulative_total_tests, 
    cdt.positive_tests, 
    cdt.cumulative_positive_tests
FROM covid19_cases_deaths_tests cdt
LEFT JOIN CTE_county_populations cp ON cdt.area = cp.area 
WHERE 
    cdt.area NOT IN('Out of state','Unknown') AND
    cdt.date IS NOT NULL AND 
    cdt.area IS NOT NULL AND  
    cdt.area_type IS NOT NULL AND
    cdt.cases IS NOT NULL AND
    cdt.cumulative_cases IS NOT NULL AND
    cdt.deaths IS NOT NULL AND
    cdt.cumulative_deaths IS NOT NULL AND
    cdt.total_tests IS NOT NULL AND
    cdt.cumulative_total_tests IS NOT NULL AND
    cdt.positive_tests IS NOT NULL AND
    cdt.cumulative_positive_tests IS NOT NULL

-- Saved output as new .csv file, covid19_cases_deaths_tests_cumulative_totals.

SELECT
    cdt.date,
    cdt.area,
    cdt.area_type,
    cdt.cumulative_cases,
    cdt.cumulative_deaths,
    cdt.cumulative_total_tests,
    cdt.cumulative_positive_tests
FROM 
    (SELECT * FROM covid19_cases_deaths_tests
    WHERE area NOT IN('Out of state','Unknown')) cdt
WHERE 
    cdt.date=(SELECT MAX(cdt2.date)
              FROM
                (SELECT * FROM covid19_cases_deaths_tests
                 WHERE 
                    area NOT IN('Out of state','Unknown') AND
                    date IS NOT NULL AND 
                    area IS NOT NULL AND  
                    area_type IS NOT NULL AND
                    population IS NOT NULL AND
                    cases IS NOT NULL AND
                    cumulative_cases IS NOT NULL AND
                    deaths IS NOT NULL AND
                    cumulative_deaths IS NOT NULL AND
                    total_tests IS NOT NULL AND
                    cumulative_total_tests IS NOT NULL AND
                    positive_tests IS NOT NULL AND
                    cumulative_positive_tests IS NOT NULL) cdt2
              WHERE cdt2.area=cdt.area)


-- CA Cumulative Cases and Deaths By Demographics: To assess the current cumulative cases and deaths by demographics, 
-- need to merge demographic population values from another dataset and select latest records for cumulative reported values.

-- Saved output as new .csv file, covid19_cumulative_cases_deaths_demographics.
-- Note that there is a limitation on demographic populations, with population estimates not accounting for 'Other' or 'Unknown' on race/ethnicity.

WITH CTE_demographic_populations AS
    (SELECT
        CASE race_ethnicity 
           WHEN 'White NH' THEN 'White' 
           WHEN 'Black NH' THEN 'Black'
           WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
           WHEN 'Asian NH' THEN 'Asian'
           WHEN 'NHPI NH' THEN 'Native Hawaiian and other Pacific Islander'
           WHEN 'MR NH' THEN 'Multi-Race'
           WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE race_ethnicity 
            WHEN 'White NH' THEN 'White' 
            WHEN 'Black NH' THEN 'Black'
            WHEN 'AIAN NH' THEN 'American Indian or Alaska Native'
            WHEN 'Asian NH' THEN 'Asian'
            WHEN 'NHPI NH' THEN 'Native Hawaiian and other Pacific Islander'
            WHEN 'MR NH' THEN 'Multi-Race'
            WHEN 'Hispanic' THEN 'Latino'
        ELSE race_ethnicity END
    UNION
    SELECT
        sex AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY sex
    UNION
    SELECT
        CASE
            WHEN age BETWEEN 0 AND 17 THEN '0-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+' 
        END AS demographic_value,
        SUM(population_2020) AS demographic_population_2020
    FROM p3_california_and_counties_v2
    GROUP BY
        CASE
            WHEN age BETWEEN 0 AND 17 THEN '0-17'
            WHEN age BETWEEN 18 AND 49 THEN '18-49'
            WHEN age BETWEEN 50 AND 64 THEN '50-64'
            WHEN age >=65 THEN '65+'
        END)

SELECT
    cd.demographic_category,
    cd.demographic_value,
    cd.report_date AS last_reporting_date,
    cd.total_cases,
    cd.deaths AS total_deaths,
    dp.demographic_population_2020,
    (SELECT SUM(population_2020) FROM p3_california_and_counties_v2) AS total_state_population_2020
FROM covid19_cases_by_demographics cd
LEFT JOIN CTE_demographic_populations dp ON cd.demographic_value=dp.demographic_value
WHERE cd.report_date=
    (SELECT MAX(cd2.report_date)
    FROM covid19_cases_by_demographics cd2
    WHERE cd2.demographic_value=cd.demographic_value)
ORDER BY cd.demographic_category ASC, cd.demographic_value ASC

-- Checking for NULL values in original dataset, covid19_cases_by_demographics.
-- Total of 20 rows affected (13742 rows in original dataset).
-- All NULLs have demographic value='Missing','Unknown' with percent_of_ca_population as NULL.  Does not impact saved output.

SELECT * FROM covid19_cases_by_demographics
WHERE
    demographic_category IS NULL OR
    demographic_value IS NULL OR
    total_cases IS NULL OR
    percent_cases IS NULL OR
    deaths IS NULL OR
    percent_deaths IS NULL OR
    percent_of_ca_population IS NULL OR
    report_date IS NULL

-- Checking for duplicate records in original dataset, covid19_cases_by_demographics. No duplicate records found.

SELECT demographic_category, demographic_value, report_date, COUNT(*) AS duplicate_records
FROM covid19_cases_by_demographics
GROUP BY demographic_category, demographic_value, report_date
HAVING COUNT(*) > 1

-- Verifying distinct demographic values for the two datasets joined.

SELECT DISTINCT race_ethnicity, race_ethnicity_code FROM p3_california_and_counties_v2

SELECT DISTINCT age FROM p3_california_and_counties_v2
ORDER BY age ASC

SELECT DISTINCT sex FROM p3_california_and_counties_v2

SELECT DISTINCT demographic_value
FROM covid19_cases_by_demographics
ORDER BY demographic_value ASC


-- CA Hospitals By County: To assess CA COVID-19 hospitalizations, two time series datasets will be generated for county-level and state-level.

-- Exploring the original dataset covid19_hospital_by_county revealed possible data entry issues with reported dates from mid-May to early-June, where there were 
-- significant value changes over a 3.5 week period.  As an example, Los Angeles had all_hospital_beds increase from 29,977 (2023-05-19) to 100,084 (2023-06-07).  
-- Los Angeles also had a roughly 85% percent difference in 2023-05-31 reported values for hospitalized covid-confirmed patients when compared against what was reported 
-- on the local county dashboard (1629 vs ~250). For this analysis, only data entries up until 2023-05-12 will be used since that was the latest date utilized by CA Department of Public Health 
-- for their Tableau dashboards.

-- Checking for NULL values in original dataset, covid19_hospital_by_county.  Total of 2020 rows affected (64060 rows in original dataset).
-- 1429 affected rows are due to hospitalized_covid_patients='NULL' OR all_hospital_beds='NULL'.
-- 0 of these rows affected are due to county='NULL' or todays_date='NULL'.
-- These NULLs are likely due to hospitals reporting out varying data.  The saved outputs will be including all observations to provide a more
-- complete perspective for the time series.  NULLs treated as 0 for the summations.  

SELECT * FROM covid19_hospital_by_county
WHERE
    county IS NULL OR
    todays_date IS NULL OR
    hospitalized_covid_confirmed_patients IS NULL OR
    hospitalized_suspected_covid_patients IS NULL OR
    hospitalized_covid_patients IS NULL OR
    all_hospital_beds IS NULL OR
    icu_covid_confirmed_patients IS NULL OR
    icu_suspected_covid_patients IS NULL OR
    icu_available_beds IS NULL

-- Checking for duplicate records in original dataset, covid19_hospital_by_county.  No duplicate records found.

SELECT county, todays_date, COUNT(*) AS duplicate_records
FROM covid19_hospital_by_county
GROUP BY county, todays_date
HAVING COUNT(*) > 1 

-- Saved below query output as new .csv file, covid19_hospitalization_county_level_timeseries.

SELECT *
FROM covid19_hospital_by_county
WHERE todays_date NOT IN('2023-06-07', '2023-05-31', '2023-05-25', '2023-05-19')
ORDER BY todays_date DESC

-- Saved below query output as new .csv file, covid19_hospitalization_state_level_timeseries.

SELECT
    todays_date,
    SUM(hospitalized_covid_confirmed_patients) AS total_hospitalized_covid_confirmed_patients,
    SUM(hospitalized_suspected_covid_patients) AS total_hospitalized_suspected_covid_patients,
    SUM(hospitalized_covid_patients) AS total_hospitalized_covid_patients,
    SUM(all_hospital_beds) AS total_hospital_beds,
    SUM(icu_covid_confirmed_patients) AS total_icu_covid_confirmed_patients,
    SUM(icu_suspected_covid_patients) AS total_icu_suspected_covid_patients,
    SUM(icu_available_beds) AS icu_available_beds
FROM covid19_hospital_by_county
WHERE todays_date NOT IN('2023-06-07', '2023-05-31', '2023-05-25', '2023-05-19')
GROUP BY todays_date
ORDER BY todays_date DESC
