-- create database and use it
create database if not exists CovidData ;
use CovidData;


-- exploring the deathData table
select * from DeathData ; 


-- we can see that some records don't have a continent value, so in our case we will delete them
delete from DeathData where  continent is  null;


-- create a view containing the columns that are interesting for us in the death table
create view deathDataView as
select Location, date, total_cases, new_cases, new_deaths , total_deaths
from DeathData order by location , date;

-- time to start exploring the view
-- size of dataset
select count(*) from deathDataView; 


# shows what is likelihood of dying after getting covid

-- first let's see what continents we have 
select distinct(continent) from deathData;

-- death rate for all countries
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 'Death Rate' from deathDataView;

-- death   for morocco 
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 'Death Rate' from deathDataView where location='Morocco';

-- countries with highest death rate 
select location, date, max((total_deaths/total_cases)*100) death_rate from deathDataView group by location , date order by date desc,death_rate desc limit 0,10;

-- number of total cases by continent
select max(total_deaths) Total_Number_Of_Deaths, continent from deathData group by continent , date order by date desc,Total_Number_Of_Deaths desc  limit 0,6;


# shows what is percentage of the population getting infected

-- infection rate with respect to population for morocco  
select location, date, total_cases, population, (total_cases/population)*100 percentage_of_population, total_deaths/total_cases 'Death Rate' from deathData where location='Morocco';

-- top 10 countries with highest infection rate 
select location,continent,  max((total_cases/population)*100 ) infection_rate from deathData group by location order by infection_rate desc limit 0,10;

-- number of total cases by continent
select max(total_cases) Tota_Number_Of_Cases, continent from deathData group by continent , date order by date desc,Tota_Number_Of_Cases desc  limit 0,6;


#Global nmbers 

-- Sums 
select date, sum(new_cases) 'Global Number Of New Cases', sum(total_cases) 'Cumulative number of cases', sum(total_deaths) 'Cumulative number of deaths',
		sum(new_deaths) 'New recorded deaths' from deathData group by date order by date asc;

-- Sums for the most recent date 
select date, sum(new_cases) 'Global Number Of New Cases', sum(total_cases) 'Cumulative number of cases', sum(total_deaths) 'Cumulative number of deaths',
		sum(new_deaths) 'New recorded deaths' from deathData group by date order by date desc limit 0,1;

-- Rates
select date ,sum(total_deaths)/sum(total_cases)*100 'Global death rate', sum(total_cases)/sum(population)*100 'infection rate '
from deathData d2 group by d2.date  order by date asc;



# vaccination data

-- overview 
select * from vaccinationData;

-- we can see that some records don't have a continent value, so in our case we will delete them
delete from vaccinationData where  continent is  null;

-- new vaccinations per country and over time
select location , date, new_vaccinations from vaccinationData;	

-- effect of vaccination on number of new cases 
select dea.date, dea.location, total_vaccinations, new_cases from
deathData dea
join vaccinationData vac
on dea.date = vac.date and dea.location = vac.location order by location;

-- for morocco 
select dea.date, dea.location, total_vaccinations, new_cases from
deathData dea
join vaccinationData vac
on dea.date = vac.date and dea.location = vac.location and dea.location like 'Morocco' order by location;

-- calculate total of vaccinations using window functions
select  location,date, sum(new_vaccinations) over ( partition by location order by  location, date) as totalVaccination from vaccinationData;

/*with total_vac as(
select  location,date, sum(new_vaccinations) as total_vaccin over ( partition by location order by  location, date) as totalVaccination from vaccinationData
)
select vac.location , vac.date , total_vaccin as 'total vaccination' from 
vaccinationData vac,
join total_vac
on total_vac.location = vac.location and total_vac.date = vac.date;*/

-- to calculate statistics using total_vaccinations we neeed to store it in temp table (since cte aren't supported yet on my DBMS) 
create temporary table vaccination_with_total
select  location,date, sum(new_vaccinations) over ( partition by location order by  location, date) as totalVaccination from vaccinationData;

-- now let us calculate the vaccination rate along with infection rate using joins for all countries
select dea.location, dea.date, round(totalVaccination/population*100 ,2)vaccincat, round(total_cases/population*100,2) 'infection rate'
from deathData dea
join vaccination_with_total vac
on dea.date = vac.date and dea.location = vac.location
where dea.date = '2021-12-21' ; 


-- now let us calculate the vaccination rate using joins for Morocco
select dea.location, dea.date, round(totalVaccination/population*100 ,2)vaccincat
from deathData dea
join vaccination_with_total vac
on dea.date = vac.date and dea.location = vac.location
where dea.location = 'Morocco'; 

-- countries with highest number of vaccinated people 
select location , max(continent),  max(total_vaccinations) total_vaccinated_people from vaccinationData group by location  order by total_vaccinated_people desc limit 0,10;

# Now let's how is the situation is changing over time ( specifically for Morocco) both for vaccinations, deaths, and new cases

-- To do that, we'll compare data of a day to data of the previous day and show it as relative change (percentage) 
create view previousDaysView as
select dea.date, dea.location, new_cases , new_deaths, new_vaccinations, 
lag(new_cases,1,0) over (order by date) previous_new_cases, 
lag(new_deaths,1,0) over (order by date) previous_new_deaths,
lag(new_vaccinations,1,0) over (order by date) previous_new_vaccinations
from deathData dea, vaccinationData vac 
where dea.date = vac.date and dea.location = vac.location and  dea.location like '%states%'; 

-- let's use the above view to calculate the relative change ( I rounded the value for better readibility) 
select date, location, round(((new_cases - previous_new_cases)/new_cases)*100,2), 
round(((new_deaths - previous_new_deaths)/new_deaths)*100,2), 
round(((new_vaccinations - previous_new_vaccinations))/new_vaccinations*100,2)
from previousDaysView ; 

select date, continent, max(total_cases) from deathData group by date, continent; 