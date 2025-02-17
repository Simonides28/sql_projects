-- link to csv: https://github.com/AlexTheAnalyst/MySQL-YouTube-Series
-- created in MySQL Workbench

-- PART 1
-- DATA CLEANING

select * from layoffs;

create table layoffs_staging
like layoffs;

insert into layoffs_staging
select * from layoffs;

select * from layoffs_staging;

with cte_duplicate as
(select *,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off,`date`,stage, country, funds_raised_millions) as rownum
from layoffs_staging
)
select * from cte_duplicate where rownum > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


select * from layoffs_staging2;

insert into layoffs_staging2
select *,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off,`date`,stage, country, funds_raised_millions) as rownum
from layoffs_staging;

select * from layoffs_staging2 where row_num>1;

delete from layoffs_staging2 where row_num>1;

select * from layoffs_staging2 where row_num>1;
select * from layoffs_staging2;

-- STANDARDIZING DATA
    
update layoffs_staging2
set company = trim(company);

update layoffs_staging2
set industry = "Crypto"
where industry like "Crypto%";

select distinct industry from layoffs_staging2 order by 1;

select distinct country, trim(trailing "." from country) from layoffs_staging2 order by 1;

update layoffs_staging2
set country = trim(trailing "." from country)
where country like "United States%";

select `date`, str_to_date(`date`,"%m/%d/%Y") from layoffs_staging2;

update layoffs_staging2
set `date`=str_to_date(`date`,"%m/%d/%Y");

alter table layoffs_staging2
modify column `date` date;


-- NULLS AND BLANKS

select * from layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;

select * from layoffs_staging2 where industry is null or industry = "";

select t1.company, t1.industry, t2. industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
where (t1.industry is null or t1.industry="") and t2.industry is not null;

select t1.company, t1.industry, t2. industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
where (t1.industry is null or t1.industry="") and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = "";

select * from layoffs_staging2 where company="Airbnb";

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
set t1.industry=t2.industry
where t1.industry is null
and t2.industry is not null;


-- REMOVING COLUMNS/ROWS

delimiter $$
with C_O as (
select company, count(company) co_co
from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null
group by company)
select sum(co_co) sum_co
from C_O $$

delimiter ;
select * from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;

delete from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;

alter table layoffs_staging2
drop column row_num;

select * from layoffs_staging2;


-- PART 2
-- EXPLORATORY DATA ANALYSIS

select * from layoffs_staging2;

with sn as
(select company, percentage_laid_off, count(company) as C_C
from layoffs_staging2
group by company, percentage_laid_off
having percentage_laid_off=1)
select count(C_C) as total_layoff
from sn;

select *
from layoffs_staging2
where percentage_laid_off=1
order by total_laid_off desc;

select company, sum(total_laid_off) total_gone
from layoffs_staging2
group by company
order by total_gone desc;

select year(`date`) `year`, month(`date`) `month`, country, company, sum(total_laid_off) total_gone
from layoffs_staging2
group by `year`, `month`, country, company
having `year` is not null and total_gone is not null
order by 1, 2 asc, total_gone desc;

select substring(`date`, 1,7) as `month`, country, company, sum(total_laid_off) total_gone
from layoffs_staging2
group by `month`, country, company
having `month` is not null and total_gone is not null
order by 1 asc, total_gone desc;

select substring(`date`, 1,7) as `month`, country, company, sum(total_laid_off) total_gone
from layoffs_staging2
group by `month`, country, company
having `month` is not null and total_gone is not null
order by 1 asc, total_gone desc;

with Rolling_Total as
(select substring(`date`, 1,7) as `month`, sum(total_laid_off) total_gone
from layoffs_staging2
group by `month`
having `month` is not null and total_gone is not null
order by 1 asc, total_gone desc)
select `month`, total_gone, sum(total_gone) over(order by `month`) as roll
from Rolling_Total;

select *
from layoffs_staging2;

with Company_per_Year as
(select company,year(`date`) years,sum(total_laid_off) as total_laid_off
from layoffs_staging2
group by company,year(`date`)),
Company_Year_Rank as
(select *, dense_rank() over(partition by years order by total_laid_off desc) as rankings
from Company_per_Year
where years is not null)
select * from Company_Year_Rank where rankings <=5;
