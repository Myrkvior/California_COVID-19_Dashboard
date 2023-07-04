# California COVID-19 Dashboard (Tableau)

A dynamic, comprehensive Tableau dashboard was built for providing an overview of COVID-19 in California and its associated counties.  This overview shows the current status and its associated historical data for the following key metrics: COVID-19 cases/deaths, COVID-19 hospitalization/ICU, COVID-19 testing, and COVID-19 vaccinations by state-level and county-level.  Breakdown by demographic population groups were also assessed for identifying current population needs.

This Tableau dashboard can be viewed at the following link: [Tableau California COVID-19 Dashboard](https://public.tableau.com/app/profile/sarah.upham/viz/CaliforniaCOVID-19Dashboard_16872403609220/CaliforniaCOVID-19DashboardCasesandDeaths)

T-SQL and Power Query were extensively utilized in data cleansing and data transformation to produce finalized datasets needed for the Tableau dashboard.  To view these SQL queries, please see the [VSCode_query_covid19_ca.sql](https://github.com/Myrkvior/California_COVID-19_Dashboard/blob/main/VSCode_query_covid19_ca.sql) file.

All raw data sources were pulled from the following publicly available databases:

* California Department of Public Health
  * [COVID-19 Variant Data](https://data.chhs.ca.gov/dataset/covid-19-variant-data)
  * [Statewide COVID-19 Vaccines Administered By County](https://data.chhs.ca.gov/dataset/vaccine-progress-dashboard)
  * [COVID-19 Vaccines Administered By Demographics](https://data.chhs.ca.gov/dataset/vaccine-progress-dashboard)
  * [Statewide COVID-19 Cases Deaths Tests](https://data.chhs.ca.gov/dataset/covid-19-time-series-metrics-by-county-and-state)
  * [Statewide COVID-19 Cases Deaths Demographics](https://data.chhs.ca.gov/dataset/covid-19-time-series-metrics-by-county-and-state)
  * [Statewide COVID-19 Hospital County Data](https://data.ca.gov/dataset/covid-19-hospital-data1)
* California Department of Finance
  * [P-3 Race/Ethnicity and Sex By Age for California and Counties](https://dof.ca.gov/forecasting/demographics/projections/)
* United States Census Bureau
  * [Counties, 1:500,000 (National) Shapefile](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.2020.html)
 
The dashboard banner design was constructed from a public domain image courtesy of National Institute of Allergy and Infectious Diseases.
  * [SARS-CoV-2 NIAID Image](https://www.flickr.com/photos/niaid/50022374313/in/album-72157712914621487/)
