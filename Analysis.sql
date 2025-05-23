USE md_water_services;

# 1. Get to know our data
SHOW TABLES;

select *
from location
limit 10;

select *
from visits
limit 10;


#water source#
select *
from water_source
limit 10;

select distinct(type_of_water_source)
from water_source
limit 10;

#3 unpack visits
select *
from visits
where time_in_queue > 500
limit 10;

# types of water sources for AkKi00881224, SoRu37635224 and SoRu36096224
select *
from water_source
where source_id in ("AkKi00881224", "SoRu37635224", "SoRu36096224");

#types of water sources for AkRu05234224, HaZa21742224
select *
from water_source
where source_id in ("AkRu05234224", "HaZa21742224");



# 4. Assess the quality of water sources
#MULTIPLE VISTIS
select *
from water_quality
where visit_count >=2 
order by visit_count desc;

#TAP WATER ONLY WITH TWO VISITS
select *
from water_quality
where subjective_quality_score = 10
and visit_count = 2;

# COUNT OF TAP WATER WITH TWO VISITS
select COUNT(*)
from water_quality
where subjective_quality_score = 10
and visit_count = 2;



# 5.  Investigating pollution issues

#exploring well pollution table
select *
from well_pollution
limit 10;

# checks if the results is Clean but the biological column is > 0.01
select *
from well_pollution
where 	results = "clean" 
	and biological > 0.01;
# the count
select count(*)
from well_pollution
where 	results = "clean" 
	and biological > 0.01;

# searching for description errors that comtained clean

select *
from well_pollution
where description like "clean%"
	and biological > 0.01;
#the count
select count(*) as total_clean_errors
from well_pollution
where description like "clean%"
	and biological > 0.01;
    
# fixing these descriptions so that we don’t encounter this issue again in the future
SET SQL_SAFE_UPDATES = 0;

UPDATE 
	md_water_services.well_pollution
SET
	description = "Bacteria: E. coli"
WHERE
	description = "Clean Bacteria: E. coli";

UPDATE 
	md_water_services.well_pollution    
SET
	description = "Bacteria: Giardia Lamblia"
WHERE
	description = "Clean Bacteria: Giardia Lamblia";
    
CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT
*
FROM
md_water_services.well_pollution
);


UPDATE
	well_pollution_copy
SET
	description = 'Bacteria: E. coli'
WHERE
	description = 'Clean Bacteria: E. coli';
    
UPDATE
	well_pollution_copy
SET
	description = 'Bacteria: Giardia Lamblia'
WHERE
	description = 'Clean Bacteria: Giardia Lamblia';
    
UPDATE
	well_pollution_copy
SET
	results = 'Contaminated: Biological'
WHERE
	biological > 0.01 AND results = 'Clean';

# Testing
select *
from well_pollution
where description like "clean%"
	and biological > 0.01;
#the count
select count(*) as total_clean_errors
from well_pollution
where description like "clean%"
	and biological > 0.01;
    
SELECT *
FROM
	well_pollution_copy
WHERE
	description LIKE "Clean_%"
	OR (results = "Clean" AND biological > 0.01);
    
# we can change the table back to the well_pollution and delete the well_pollution_copy table.

UPDATE
well_pollution_copy
SET
	description = 'Bacteria: E. coli'
WHERE
	description = 'Clean Bacteria: E. coli';
UPDATE
	well_pollution_copy
SET
	description = 'Bacteria: Giardia Lamblia'
WHERE
	description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
	well_pollution_copy
SET
	results = 'Contaminated: Biological'
WHERE
	biological > 0.01 AND results = 'Clean';
DROP TABLE
	md_water_services.well_pollution_copy;
    
    
# the address of Bello Azibo

select *
from employee
where employee_name = "Bello Azibo";

# name and phone number of our Microbiologist
select *
from employee
where employee_name = "Vuyisile Ghadir";


# the source_id of the water source shared by the most number of people? Hint: Use a comparison operato


select source_id,
	max(number_of_people_served)
from water_source
group by source_id;

select *
from water_source
where number_of_people_served = 3998;

select *
from data_dictionary;

select *
from global_water_access
where name = "maji ndogo";

SELECT *
FROM employee
WHERE phone_number like "%86%" or "%11%"
and employee_name like "A%" or "M%"
and position = "Field Surveyor";

SELECT count(*)
FROM well_pollution
WHERE description LIKE 'Clean_%' OR results = 'Clean' AND biological < 0.01;

SELECT * FROM water_quality WHERE visit_count >= 2 AND subjective_quality_score = 10;
SELECT * FROM water_quality WHERE visit_count = 2 AND subjective_quality_score = 10;
SELECT * FROM water_quality WHERE visit_count > 1 AND subjective_quality_score > 10;
SELECT * FROM water_quality WHERE visit_count = 2 OR subjective_quality_score = 10;

SELECT count(*) as total_errors_in_recording_clean
FROM well_pollution
WHERE description
IN ('Parasite: Cryptosporidium', 'biologically contaminated')
OR (results = 'Clean' AND biological > 0.01);

select pop_n
from global_water_access;

SELECT count(*)
FROM well_pollution
WHERE description LIKE 'Clean %' OR results = 'Clean' AND biological < 0.01;


USE md_water_services;
select *
from auditor_report
limit 10;
