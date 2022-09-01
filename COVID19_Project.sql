--- The last update before this data was dowloaded 2022-08-27
--- Checking the tables to confirm components of datasets

SELECT
     *
FROM
    PortfolioProject..Covid19Deaths$
WHERE continent IS NOT NULL
ORDER BY
    location, date

SELECT
     *
FROM
    PortfolioProject..Covid19Vaccinations$
WHERE continent IS NOT NULL
ORDER BY
    location, date

--- Select data that we will be using

SELECT
    location, date, total_cases, total_deaths, population
FROM
    PortfolioProject..Covid19Deaths$
WHERE continent IS NOT NULL
ORDER BY 
    location, date

--- Checking for Total cases and Total deaths
--- This shows the likelihood of dying if you contract Covid in your country.
--- Here, I filtered to see the death percentage in Nigeria,
--- because it's relevant to me.

SELECT
    location, date, total_cases, total_deaths,
	(
	 total_deaths/total_cases
	 ) * 100 AS DeathPercentage
FROM
    PortfolioProject..Covid19Deaths$
WHERE location = 'Nigeria'
AND continent IS NOT NULL
ORDER BY 
    location, date
	DESC

--- Checking for Total cases vs Population
--- This shows what percentage of population got Covid

SELECT
    location, date, population, total_cases,
	(
	 total_cases/population
	 ) * 100 AS PercentPopulationInfected
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE continent IS NOT NULL
ORDER BY 
    location, date

--- Checking for Countries with highest Infection Rate compared to Population

SELECT
    location, population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX(total_cases/population
	 ) * 100 AS PercentPopulationInfected
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE continent IS NOT NULL
GROUP BY
    continent, population
ORDER BY 
    PercentPopulationInfected

--- Showing Countries with highest death count per population
--- Converted data type of 'total_deaths' from 'varchar' to 'integer'
--- so that it counts as numbers and not as strings

SELECT
    location, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCounts
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE continent IS NOT NULL
GROUP BY
    continent
ORDER BY 
   TotalDeathCounts

--- Let's Break Things Down By Continent
--- Showing continents with the highest death count per population

SELECT
    continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCounts
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE continent IS NOT NULL
GROUP BY
    continent
ORDER BY 
   TotalDeathCounts

--- Global Numbers

SELECT
      date, 
	  SUM(new_cases) AS total_cases,
	  SUM(CAST(new_deaths AS int)) AS total_deaths,
	  SUM(CAST(new_deaths AS int)
	  )/SUM(new_cases)* 100 AS DeathPercentage
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE
    continent IS NOT NULL
GROUP BY date
ORDER BY 
    total_cases, total_deaths

SELECT 
	  SUM(new_cases) AS total_cases,
	  SUM(CAST(new_deaths AS int)) AS total_deaths,
	  SUM(CAST(new_deaths AS int)
	  )/SUM(new_cases)* 100 AS DeathPercentage
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE
    continent IS NOT NULL
ORDER BY 
    total_cases, total_deaths


--- Joining the Covid19Deaths Table and the Covid19Vaccination

SELECT
     *
FROM
	 PortfolioProject..Covid19Deaths$ dea
JOIN PortfolioProject..Covid19Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date

--- Looking at Total Population vs Vaccination

SELECT
     dea.continent, dea.location, dea.date, dea.population,
	 vac.new_vaccinations
FROM
	 PortfolioProject..Covid19Deaths$ dea
JOIN PortfolioProject..Covid19Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

--- Rolling Count of People Vaccinated

SELECT
     dea.continent, 
	  dea.Location, 
	   dea.date, 
	    dea.population,
		  vac.new_vaccinations,
	 SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER(PARTITION BY 
	     dea.location 
		ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
   PortfolioProject..Covid19Deaths$ dea
   JOIN PortfolioProject..Covid19Vaccinations$ vac
  ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

--- Use CTE

WITH
    PopvsVac
	(continent, location, date,
	population, new_vaccinations,
	RollingPeopleVaccinated)AS
(
SELECT
     dea.continent, 
	  dea.Location, 
	   dea.date, 
	    dea.population,
		  vac.new_vaccinations,
	 SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER(PARTITION BY 
	     death.location
		 ORDER BY death.date) AS RollingPeopleVaccinated
		    ---,(RollingPeopleVaccinated/Population) * 100
FROM 
   PortfolioProject..Covid19Deaths$ dea
   JOIN PortfolioProject..Covid19Vaccinations$ vac
  ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
---ORDER BY death.location, death.date
)
SELECT 
   *,
   (RollingPeopleVaccinated/Population) * 100
FROM PopvsVac

--- Temp Table

DROP TABLE IF EXISTS PercentPopVaccinated
CREATE TABLE PercentPopVaccinated
       (
	   Continent nvarchar(255),
	   Loction nvarchar(255),
	   Date datetime,
	   Population numeric,
	   New_vaccinations numeric,
	   RollingPeopleVaccinated numeric
	   )
INSERT INTO PercentPopVaccinated
SELECT
     dea.continent, 
	  dea.Location, 
	   dea.date, 
	    dea.population,
		  vac.new_vaccinations,
	 SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER(PARTITION BY 
	     dea.location
		 ORDER BY dea.date) AS RollingPeopleVaccinated
		    ---,(RollingPeopleVaccinated/Population) * 100
FROM 
   PortfolioProject..Covid19Deaths$ dea
   JOIN PortfolioProject..Covid19Vaccinations$ vac
  ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
---ORDER BY dea.location, dea.date
SELECT 
   *,
   (RollingPeopleVaccinated/Population) * 100
FROM PercentPopVaccinated

--- Creating Views to store data for later
--- visulization

CREATE VIEW PercentagePopVaccinated AS
SELECT
     dea.continent, 
	  dea.Location, 
	   dea.date, 
	    dea.population,
		  vac.new_vaccinations,
	 SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER(PARTITION BY 
	     dea.location
		 ORDER BY dea.date) AS RollingPeopleVaccinated
		    ---,(RollingPeopleVaccinated/Population) * 100
FROM 
   PortfolioProject..Covid19Deaths$ dea
   JOIN PortfolioProject..Covid19Vaccinations$ vac
  ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
---ORDER BY dea.location, dea.date


CREATE VIEW GlobalNumbers AS
SELECT
      date, 
	  SUM(new_cases) AS total_cases,
	  SUM(CAST(new_deaths AS int)) AS total_deaths,
	  SUM(CAST(new_deaths AS int)
	  )/SUM(new_cases)* 100 AS DeathPercentage
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE
    continent IS NOT NULL
GROUP BY date
---ORDER BY 
    --total_cases, total_deaths


CREATE VIEW DeathCountsByContinent AS
SELECT
    continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCounts
FROM
    PortfolioProject..Covid19Deaths$
--- Where location is 'Nigeria'
WHERE continent IS NOT NULL
GROUP BY
    continent
---ORDER BY 
  --- TotalDeathCounts



 CREATE VIEW TotalCasesandDeathsinNigeria AS
 SELECT
    location, date, total_cases, total_deaths,
	(
	 total_deaths/total_cases
	 ) * 100 AS DeathPercentage
FROM
    PortfolioProject..Covid19Deaths$
WHERE location = 'Nigeria'
AND continent IS NOT NULL
---ORDER BY 
  ---  location, date
	---DESC