/* 
Here I am exploring COVID 19 data as of Feb. 16, 2022
Skills used include: Converting data types, creating views, aggregate functions, Joins, CTEs, temp tables
*/

-- data exploration
SELECT *
FROM portfolio_project..Covid_Deaths
ORDER by 3,4
-- data exploration
SELECT *
FROM portfolio_project..Covid_Vaccinations
ORDER by 3,4

--Selecting data to use
SELECT Location, date, population, total_cases, new_cases, total_deaths
FROM portfolio_project..Covid_Deaths
ORDER by 1,2

-- Looking at total cases vs total deaths
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM portfolio_project..Covid_Deaths
WHERE Location like '%states%'
ORDER by 1,2

-- Total cases vs Population for US
SELECT Location, date, population, total_cases, (total_cases/population)*100 as Infection_Percentage
FROM portfolio_project..Covid_Deaths
WHERE Location like '%states%'
ORDER by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as Percent_Population_Infected
FROM portfolio_project..Covid_Deaths
Group by Location, Population
order by Percent_Population_Infected desc

-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as Total_Death_Count
FROM portfolio_project..Covid_Deaths
Where continent is not null 
Group by Location
order by Total_Death_Count desc

-- Continents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as Total_Death_Count
FROM portfolio_project..Covid_Deaths
Where continent is not null 
Group by continent
order by Total_Death_Count desc

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM portfolio_project..Covid_Deaths
where continent is not null 
order by 1,2

-- Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date)
as rolling_vaccination
FROM portfolio_project..Covid_Deaths dea
JOIN portfolio_project..Covid_Vaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3

-- Useing a  CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date)
as rolling_vaccination
FROM portfolio_project..Covid_Deaths dea
JOIN portfolio_project..Covid_Vaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_vaccination/population)*100 as rolling_percentage
FROM PopvsVac

-- Using a temp table instead of CTE
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_vaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date)
as rolling_vaccination
FROM portfolio_project..Covid_Deaths dea
JOIN portfolio_project..Covid_Vaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, (rolling_vaccination/population)*100 as rolling_percentage
FROM #PercentPopulationVaccinated

-- Creating a view for data visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date)
as rolling_vaccination
FROM portfolio_project..Covid_Deaths dea
JOIN portfolio_project..Covid_Vaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL