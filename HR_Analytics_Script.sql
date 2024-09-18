-- create database
CREATE DATABASE hr;

-- after loading database
USE hr;

-- explore the loaded data into hr_table
SELECT *
FROM hr_table;

-- explore table structure
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'hr_table';

-- Fix column "termdate" formatting
-- format termdate datetime UTC values
-- Update date/time to date
UPDATE hr_table
SET termdate = FORMAT(CONVERT(DATETIME, LEFT(termdate, 19), 120), 'yyyy-MM-dd');

-- Update from nvachar to date
ALTER TABLE hr_table
ADD new_termdate DATE;

-- Update the new date column with the converted values
UPDATE hr_table
SET new_termdate = CASE
    WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1
        THEN CAST(termdate AS DATETIME)
        ELSE NULL
    END;

SELECT new_termdate
FROM hr_table
ORDER BY new_termdate desc;

-- create new column "age"
ALTER TABLE hr_table
ADD age nvarchar(50);

-- populate new column with age
UPDATE hr_table
SET age = DATEDIFF(YEAR, birthdate, GETDATE());

SELECT birthdate, age
FROM hr_table
ORDER BY age;

-- min and max ages
SELECT 
 MIN(age) AS min_age, 
 MAX(AGE) AS max_age
FROM hr_table;

-- BUSINESS QUESTIONS TO ANSWER FROM THE DATA

-- 1) What's the age distribution in the company?
SELECT 
 MIN(age) AS Youngest, 
 MAX(age) AS Oldest
FROM hr_table;

-- age distribution
SELECT
  age_group,
  COUNT(*) AS count
FROM (
  SELECT
    CASE
      WHEN age >= 21 AND age <= 30 THEN '21 to 30'
      WHEN age >= 31 AND age <= 40 THEN '31 to 40'
      WHEN age >= 41 AND age <= 50 THEN '41-50'
      ELSE '50+'
    END AS age_group
  FROM hr_table
  WHERE new_termdate IS NULL
) AS Subquery
GROUP BY age_group
ORDER BY age_group;

-- age group by gender
SELECT
  age_group,
  gender,
  COUNT(*) AS count
FROM (
  SELECT
    CASE
      WHEN age >= 21 AND age <= 30 THEN '21 to 30'
      WHEN age >= 31 AND age <= 40 THEN '31 to 40'
      WHEN age >= 41 AND age <= 50 THEN '41-50'
      ELSE '50+'
    END AS age_group,
	gender
  FROM hr_table
  WHERE new_termdate IS NULL
) AS Subquery
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- 2) What's the gender breakdown in the company?
SELECT
 gender,
 COUNT(gender) AS count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY gender
ORDER BY gender ASC;

-- 3) How does gender vary across departments and job titles?
SELECT department, gender, count(*) as count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY department, gender
ORDER BY department;

-- job titles
SELECT 
department, jobtitle,
gender,
count(gender) AS count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender ASC;

-- 4) What's the race distribution in the company?
SELECT race,
 COUNT(*) AS count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY race
ORDER BY count DESC;

-- 5) What's the average length of employment in the company?
SELECT
 AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
 FROM hr_table
 WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();

-- 6) Which department has the highest turnover rate?
-- get total count
-- get terminated count
-- terminated count/total count
SELECT
 department,
 total_count,
 terminated_count,
 round(CAST(terminated_count AS FLOAT)/total_count, 2) AS turnover_rate
FROM 
   (SELECT
   department,
   count(*) AS total_count,
   SUM(CASE
        WHEN new_termdate IS NOT NULL AND new_termdate <= getdate()
		THEN 1 ELSE 0
		END
   ) AS terminated_count
  FROM hr_table
  GROUP BY department
  ) AS Subquery
ORDER BY turnover_rate DESC;

-- 7) What is the tenure distribution for each department?

--SELECT 
--    department,
--    AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
--FROM 
--    hr_table
--WHERE 
--    new_termdate IS NOT NULL 
--    AND new_termdate <= GETDATE()
--GROUP BY 
--    department;

SELECT 
 department, DATEDIFF(year, MIN(hire_date), MAX(new_termdate)) AS tenure
FROM hr_table
WHERE  new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department
ORDER BY tenure DESC;

-- 8) How many employees work remotely for each department?
SELECT
 location,
 count(*) AS count
 FROM hr_table
 WHERE new_termdate IS NULL
 GROUP BY location;

-- 9) What's the distribution of employees across different states?
SELECT
location_state,
count(*) AS count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

-- 10) How are job titles distributed in the company?
SELECT 
 jobtitle,
 count(*) AS count
FROM hr_table
WHERE new_termdate IS NULL
GROUP BY jobtitle
ORDER BY count DESC;

-- 11) How have employee hire counts varied over time?
SELECT
hire_yr,
hires,
terminations,
hires - terminations AS net_change,
(hires - terminations)/hires AS percent_hire_change
FROM  
  (SELECT
  YEAR(hire_date) AS hire_yr,
  count(*) as hires,
  SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
  FROM hr_table
  GROUP BY year(hire_date)
  ) AS subquery
ORDER BY percent_hire_change ASC;

-- fixes zero values from the above query
SELECT
    hire_yr,
    hires,
    terminations,
    hires - terminations AS net_change,
    (round(CAST(hires - terminations AS FLOAT) / NULLIF(hires, 0), 2)) *100 AS percent_hire_change
FROM  
    (SELECT
        YEAR(hire_date) AS hire_yr,
        COUNT(*) AS hires,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
    FROM hr_table
    GROUP BY YEAR(hire_date)
    ) AS subquery
ORDER BY hire_yr ASC;