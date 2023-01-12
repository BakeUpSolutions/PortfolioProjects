
-- Exploring the COVID-19 Dataset
SELECT * FROM CovidDeath$ ORDER BY location, year_reg DESC;
SELECT * FROM CovidVaccination$;

-- Add an year column to CovidDeath$ Table
ALTER TABLE CovidDeath$ add year_reg varchar(4); 
UPDATE CovidDeath$ set year_reg = year(date);

-- Remove duplicates from CovidVaccination Table
WITH cte (
	continent, 
	location, 
	date,
	dupe_count)
AS (SELECT continent,
		   location,
		   date,
		   ROW_NUMBER() OVER(PARTITION BY continent, 
										  location,
										  date
	       ORDER BY location, date) AS dupe_count
	FROM CovidVaccination$)

DELETE FROM cte
WHERE dupe_count > 1;

-- Show total quantity of countries covered within dataset
SELECT COUNT(DISTINCT location)  AS total_countries
FROM CovidDeath$;

-- Looking at Total Cases vs Total_death 
-- Shows the likelihood of dying if you contract covid in United States
SELECT
	continent, 
	location, 
	total_cases AS total_cases, 
	CAST(total_deaths AS bigint) AS total_deaths, 
	CAST(total_deaths AS bigint)/(total_cases) * 100 AS death_percentage
FROM CovidDeath$
WHERE continent IS NOT NULL
	AND location LIKE '%states%' --Filters out continent-level only rows
ORDER BY death_percentage DESC;


-- Looking at Total Cases vs Population in United States
SELECT TOP 10 
	location,
	date,
	population,
	total_cases,
	total_cases / population * 100 AS infection_rate
FROM CovidDeath$
WHERE continent IS NOT NULL
	AND location LIKE '%states%'
	AND year_reg = '2021'--Filters out continent-level only rows
ORDER BY infection_rate DESC;

--Looking at contries with the Highest Infection Rate compared to Population
SELECT TOP 25 
	location,
	population,
	MAX(total_cases) AS PeakInfectionCount,
	MAX(total_cases / population) * 100 AS infection_rate
FROM CovidDeath$
WHERE continent IS NOT NULL
	AND year_reg IN('2020','2021','2022')--Filters out continent-level only rows
	GROUP BY location, population
ORDER BY infection_rate DESC;

-- Looking at countries with the Highest Death Count per Populations
SELECT TOP 25
	location, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeath$
WHERE continent IS NOT NULL
	AND year_reg IN('2020','2021','2022')
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Continental Numbers

--Looking at continents with the Highest Death Count per Populations
SELECT 
	location AS continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeath$
WHERE continent IS NULL
	AND year_reg IN('2020','2021','2022')
	AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Looking at continents with the Highest Infection Rate compared to Population
SELECT TOP 25 
	location,
	population,
	MAX(total_cases) AS PeakInfectionCount,
	MAX(total_cases / population) * 100 AS infection_rate
FROM CovidDeath$
WHERE continent IS NULL --Filters out non-continent-level specfic rows
	AND year_reg IN('2020','2021','2022') -- Filter
	AND location NOT LIKE '%income%'
	GROUP BY location, population
ORDER BY infection_rate DESC;

-- GLOBAL NUMBERS

-- Looking at Highest Death Percentage 
SELECT TOP 5 
	date,
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths as bigint)) AS total_deaths,  
	(SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100) AS DeathPercentage
FROM CovidDeath$
WHERE continent IS NOT NULL --Filters out non-continent-level specfic rows
GROUP BY date
ORDER BY DeathPercentage DESC;

-- looking at Highest Infection Rate 
SELECT TOP 5 
	date,
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths as bigint)) AS total_deaths,  
	(SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100) AS DeathPercentage
FROM CovidDeath$
WHERE continent IS NOT NULL --Filters out non-continent-level specfic rows
GROUP BY date
ORDER BY DeathPercentage DESC;


-- looking at the total amount of people in the world that has been vaccinated
-- Total Population VS Total Vaccinations
SELECT TOP 20 *
FROM CovidDeath$ AS dea
JOIN CovidVaccination$ AS vac
ON dea.location = vac.location
   AND  dea.date = vac.date;

SELECT TOP 20 dea.continent, dea.location, dea.date, dea.population, new_vaccinations
FROM CovidDeath$ AS dea
JOIN CovidVaccination$ AS vac
ON dea.location = vac.location
   AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.year_reg IN('2020')
ORDER BY 2, 3;

-- Looking at Total Population vs Vaccination
-- Why is this showing duplicate rows in the date column? CovidVaccination$ has duplicates 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
SELECT  
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(Convert(bigint,vac.new_vaccinations)) OVER(Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeath$ AS dea
JOIN CovidVaccination$ AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.date BETWEEN '2022-09-01' AND '2022-12-31'
)
SELECT *,
	RollingPeopleVaccinated/population * 100 AS PopulationVaccinatedPercentage
FROM PopvsVac
ORDER BY location, Date;

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	location varchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric,

)
INSERT INTO #PercentPopulationVaccinated
SELECT  
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(Convert(bigint,vac.new_vaccinations)) OVER(Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeath$ AS dea
JOIN CovidVaccination$ AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Percent Population View
CREATE VIEW PercentPopulationVaccinated AS
SELECT  
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(Convert(bigint,vac.new_vaccinations)) OVER(Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeath$ AS dea
JOIN CovidVaccination$ AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



