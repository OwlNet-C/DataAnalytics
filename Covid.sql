
/*
This project is looking to SQL and mess around with data regarding COVID
*/


-- Two tables in this data set : Covid Deaths and Covid Vaccinations
select * from PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
order by 3,4

select * from PortfolioProject..CovidVaccinations$
order by 3,4

-- select data that we are going to be using 

select Location,date,total_cases,new_cases,total_deaths, population
from PortfolioProject..CovidDeaths$
order by 1,2

-- Looking at the total cases vs total deaths

-- Data type of this was set to nvarchar so ive changed them to BIGINT
ALTER TABLE PortfolioProject..CovidDeaths$
ALTER COLUMN total_cases BIGINT;

ALTER TABLE PortfolioProject..CovidDeaths$
ALTER COLUMN total_deaths BIGINT;

-- Shows likelihood of dying if you contract covid in your country
select Location, date, total_deaths, total_cases,
ROUND((total_deaths/total_cases)*100,1) as DeathPercentage
from PortfolioProject..CovidDeaths$
where location like '%kingdom%'
order by 1,2

-- Looking at Total Cases vs Population 

-- Shows what percentage of population got Covid in UK
select Location, date, total_deaths,population, total_cases,
ROUND((total_cases/population)*100,3) as PercentPopulationInfected
from PortfolioProject..CovidDeaths$
where location like '%kingdom%'
--order by date desc
order by 1,2

-- Looking at Countries with high Infection rate compared to Population
-- Filter for countries on Where clause
select Location, Population ,
Max(total_cases) as Highest_Infection_Count,
MAX((total_cases/population)*100) as Percent_Population_Infected
from PortfolioProject..CovidDeaths$
-- where location = 'Andorra'
group by Location, population
order by Percent_Population_Infected desc


--Showing countries with Highest Death Count per Population
-- Using continent is not null , removes the non country entities like Asia, Europe, World that was showing up
select Location, MAX(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
group by Location, population
order by TotalDeathCount desc

--Location overview on total deaths
select location  , MAX(cast(total_deaths as INT)) as TotalDeathCount 
from PortfolioProject..CovidDeaths$
where continent is null and location not like '%income%'
group by location
order by TotalDeathCount desc

-- Location Death count percentage of whole world
select location ,
MAX(cast(total_deaths as INT)) as TotalDeathCount,
CAST(MAX(cast(total_deaths as INT)) AS float)/(select MAX(cast(total_deaths as int)) from PortfolioProject..CovidDeaths$ WHERE location = 'World') *100 as DeathCountPercentage
from PortfolioProject..CovidDeaths$
where continent is null and location not like '%income%'
group by location
order by DeathCountPercentage Desc


select continent  , MAX(cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

-- Showing Continents with Highest Death Counts

select continent , MAX(cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS
-- Weekly new cases and deaths.

select date, sum(new_cases) as TotalNewCases,
sum(cast(new_deaths as int)) as TotalNewDeaths,
ROUND(
CASE 
	when sum(new_cases) = 0 THEN NULL
	ELSE (SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100)
END
,2)
AS DeathPercentage
from PortfolioProject..CovidDeaths$
--where location like '%kingdom%'
where continent is not null 
group by date 
having 
	sum(new_cases) != 0
order by 1,2

-- TOTAL NEW CASES | TOTAL NEW DEATHS | Death Percentage
select sum(new_cases) as TotalNewCases,sum(cast(new_deaths as int)) as TotalNewDeaths,
CASE 
	when sum(new_cases) = 0 THEN NULL
	ELSE (SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100)
END AS DeathPercentage
from PortfolioProject..CovidDeaths$
--where location like '%kingdom%'
where continent is not null 
order by 1,2


-- Looking at Total Population vs Vaccinations
--Creating a rolling count to tract total vaccinations as date progresses
select dea.continent, dea.location, dea.date , dea.population, vac.new_vaccinations
, sum(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as Rolling_People_Vaccinated
from PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and dea.location = 'Albania'
order by 2,3


-- Use CTE

WITH PopvsVac (continent,location,date,population,new_vaccinations,Rolling_People_Vaccinated)
as
(
select dea.continent, dea.location, dea.date , dea.population, vac.new_vaccinations
, sum(CONVERT(BIGINT,ISNULL(vac.new_vaccinations,0))) OVER (Partition by dea.location Order by dea.location,dea.date) as Rolling_People_Vaccinated
from PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and dea.location = 'Albania'
--order by 2,3
)
select * from PopvsVac

SELECT *,
    (ISNULL(Rolling_People_Vaccinated, 0) / NULLIF(population, 0) * 100) AS Vaccination_Percentage
FROM 
    PopvsVac;

-- CHATGPT 
WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, ISNULL(vac.new_vaccinations, 0))) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS Rolling_People_Vaccinated
    FROM 
        PortfolioProject..CovidDeaths$ dea
    JOIN 
        PortfolioProject..CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
        AND dea.location = 'Albania'
)
SELECT *,
    (ISNULL(Rolling_People_Vaccinated, 0) / NULLIF(population, 0) * 100) AS Vaccination_Percentage
FROM 
    PopvsVac;


-- Creating view to store data later for visuals
--CREATING TABLES / DELETING TABLES 
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated

(Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date , dea.population, vac.new_vaccinations
, sum(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as Rolling_People_Vaccinated
from PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and dea.location = 'Albania'
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100	from #PercentPopulationVaccinated

-- Creating a view 
Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date , dea.population, vac.new_vaccinations
, sum(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as Rolling_People_Vaccinated
from PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
--order by 2,3

--DROP VIEW PortfolioProject.[PercentPopulationVaccinated];

SELECT * 
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME = 'PercentPopulationVaccinated';

