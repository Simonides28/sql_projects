-- link to xlsx: https://ourworldindata.org/covid-deaths ("Download" below the graph)
-- created in SQL Server Management Studio


-- RANDOM VISUAL CHECK OF DATA
select location,date,total_cases, new_cases, total_deaths,population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2;


-- TOTAL CASES : TOTAL DEATHS - shows likelihood of dying if contracted with covid in a specific country

select location,date,total_cases, total_deaths, round((total_deaths/total_cases)*100,3) as Death_Percentage
from PortfolioProject..CovidDeaths
where location='Slovakia'
order by Death_Percentage desc;


-- TOTAL CASES : POPULATION

select location,date,total_cases, population, round((total_cases/population)*100,3) as Perc_of_Population_Infected
from PortfolioProject..CovidDeaths
where location='Slovakia'
order by 1,2;


-- INFECTION RATE COMPARED TO POPULATION

select location, population, max(total_cases) as Highest_Inf_count,round(max((total_cases/population))*100,3) as Perc_of_Population_Infected
from PortfolioProject..CovidDeaths
group by location, population
order by Perc_of_Population_Infected desc


-- COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

select location, max(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by Total_Death_Count desc


-- STATISTICS BY CONTINENT

select continent, max(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by Total_Death_Count desc


-- CONTINENTS WITH THE HIGHEST DEATH COUNT

select continent, max(cast(total_deaths as int)) as Total_Death_Count
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by Total_Death_Count desc


-- GLOBAL NUMBERS

select date, sum(new_cases) Total_cases, sum(cast(new_deaths as int)) Total_deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100,3) as Death_Percentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2


-- TOTAL WORLD CASE : DEATH : PERCENTAGE

select sum(new_cases) Total_cases, sum(cast(new_deaths as int)) Total_deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100,3) as Death_Percentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2



-- VACCINATIONS STATISTICS


-- JOIN TABLES

select * from PortfolioProject..CovidDeaths as CD
join PortfolioProject..CovidVaccinations as CV
on CD.location=CV.location
	and CD.date=CV.date


-- POPULATION : VACCINATION

select CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,sum(convert(int,CV.new_vaccinations)) over (partition by CD.location order by CD.location, CD.date) Rolling_Total_Vac
from PortfolioProject..CovidDeaths as CD
join PortfolioProject..CovidVaccinations as CV
on CD.location=CV.location
	and CD.date=CV.date
where CD.continent is not null
order by 2,3


-- CTE

with PPLvsVAC (Continent, Location, Date, Population, New_vaccinations, Rolling_Total_Vac) as
(
select CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,sum(convert(int,CV.new_vaccinations)) over (partition by CD.location order by CD.location, CD.date) Rolling_Total_Vac
from PortfolioProject..CovidDeaths as CD
join PortfolioProject..CovidVaccinations as CV
on CD.location=CV.location
	and CD.date=CV.date
where CD.continent is not null
-- order by 2,3
)
select *, (Rolling_Total_Vac/population)*100 Percentage_Vaccinated from PPLvsVAC
order by 2,3


-- TEMP TABLE

drop table if exists PercentPopulationVaccinated

create table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_Total_Vac numeric
)

insert into PercentPopulationVaccinated
select CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,sum(convert(int,CV.new_vaccinations)) over (partition by CD.location order by CD.location, CD.date) Rolling_Total_Vac
from PortfolioProject..CovidDeaths as CD
join PortfolioProject..CovidVaccinations as CV
on CD.location=CV.location
	and CD.date=CV.date
-- where CD.continent is not null
-- order by 2,3

select *, (Rolling_Total_Vac/population)*100
from PercentPopulationVaccinated


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

create view PercPopulationVaccinated as
select CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,
sum(convert(int,CV.new_vaccinations)) over (partition by CD.location order by CD.location, CD.date) Rolling_Total_Vac
from PortfolioProject..CovidDeaths as CD
join PortfolioProject..CovidVaccinations as CV
on CD.location=CV.location
	and CD.date=CV.date
where CD.continent is not null
