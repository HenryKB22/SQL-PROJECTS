USE md_water_services;
select location_id,
true_water_source_score
from auditor_report
limit 100;


with aud_vis as 
(
# combining visits and audit report tables
SELECT
 aud.location_id AS audit_location,
 aud.true_water_source_score as true_water_source_score,
 aud.type_of_water_source as type_of_water_sources,
 vis.location_id AS visit_location,
 vis.record_id,
 vis.source_id as source_id,
 vis.visit_count
FROM auditor_report as aud
JOIN visits as vis 
on aud.location_id = vis.location_id
)
# combining visits, audit report and water quality tables
select
	aud_vis.audit_location,
	aud_vis.record_id,
    aud_vis.true_water_source_score as auditor_score,
    wq.subjective_quality_score as surveyor_score
from aud_vis 
join water_quality as wq
on aud_vis.record_id = wq.record_id
# checking where auditor_score and surveyor scores are the same
where aud_vis.true_water_source_score != wq.subjective_quality_score
and aud_vis.visit_count = 1;


-- Combining visits, audit report and water quality tables
WITH aud_vis AS (
    -- Combining visits and audit report tables
    SELECT
        aud.location_id AS audit_location,
        aud.true_water_source_score AS true_water_source_score,
        aud.type_of_water_source AS type_of_water_sources,
        vis.location_id AS visit_location,
        vis.record_id,
        vis.source_id AS source_id,
        vis.visit_count
    FROM auditor_report AS aud
    JOIN visits AS vis
    ON aud.location_id = vis.location_id
),
awv AS (
    -- Combining visits, audit report and water quality tables
    SELECT
        aud_vis.audit_location,
        aud_vis.record_id,
        aud_vis.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score,
        aud_vis.visit_count,
        aud_vis.type_of_water_sources,
        aud_vis.source_id
    FROM aud_vis
    JOIN water_quality AS wq
    ON aud_vis.record_id = wq.record_id
    -- Checking where auditor_score and surveyor scores are different and visit_count = 1
    WHERE aud_vis.true_water_source_score != wq.subjective_quality_score
    AND aud_vis.visit_count = 1
)
SELECT
    awv.audit_location,
    awv.auditor_score,
    awv.surveyor_score,
    awv.record_id,
    awv.type_of_water_sources AS auditor_source,
    ws.type_of_water_source AS survey_source
FROM water_source AS ws
JOIN awv
ON ws.source_id = awv.source_id;


-- Once you're done, remove the columns and JOIN statement for water_sources again.
WITH aud_vis AS (
    -- Combining visits and audit report tables
    SELECT
        aud.location_id AS audit_location,
        aud.true_water_source_score AS true_water_source_score,
        aud.type_of_water_source AS type_of_water_sources,
        vis.location_id AS visit_location,
        vis.record_id,
        vis.source_id AS source_id,
        vis.visit_count
    FROM auditor_report AS aud
    JOIN visits AS vis
    ON aud.location_id = vis.location_id
),
awv AS (
    -- Combining visits, audit report and water quality tables
    SELECT
        aud_vis.audit_location,
        aud_vis.record_id,
        aud_vis.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score,
        aud_vis.visit_count,
        aud_vis.type_of_water_sources
    FROM aud_vis
    JOIN water_quality AS wq
    ON aud_vis.record_id = wq.record_id
    -- Checking where auditor_score and surveyor scores are different and visit_count = 1
    WHERE aud_vis.true_water_source_score != wq.subjective_quality_score
    AND aud_vis.visit_count = 1
)
SELECT
    awv.audit_location,
    awv.auditor_score,
    awv.surveyor_score,
    awv.type_of_water_sources AS auditor_source
FROM awv;


-- Linking records to employees
WITH aud_vis AS (
    -- Combining visits and audit report tables
    SELECT
        aud.location_id AS audit_location,
        aud.true_water_source_score AS true_water_source_score,
        aud.type_of_water_source AS type_of_water_sources,
        vis.location_id AS visit_location,
        vis.record_id,
        vis.source_id AS source_id,
        vis.visit_count,
        vis.assigned_employee_id as employee_id
    FROM auditor_report AS aud
    JOIN visits AS vis
    ON aud.location_id = vis.location_id
),
awv AS (
    -- Combining visits, audit report and water quality tables
    SELECT
        aud_vis.audit_location,
        aud_vis.record_id,
        aud_vis.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score,
        aud_vis.visit_count,
        aud_vis.type_of_water_sources,
        aud_vis.source_id,
        aud_vis.employee_id
    FROM aud_vis
    JOIN water_quality AS wq
    ON aud_vis.record_id = wq.record_id
    -- Checking where auditor_score and surveyor scores are different and visit_count = 1
    WHERE aud_vis.true_water_source_score != wq.subjective_quality_score
    AND aud_vis.visit_count = 1
),
 Incorrect_records as(
 -- Linking records to employees
SELECT
    awv.audit_location,
    awv.auditor_score,
    awv.surveyor_score,
    awv.record_id,
    awv.type_of_water_sources AS auditor_source,
-- employees who made the mistakes
    e.employee_name
FROM employee AS e
JOIN awv
ON e.assigned_employee_id = awv.employee_id
),
 error_count as(
-- total mistakes by each employee
select 
	employee_name,
    count(*) as total_mistakes
from  Incorrect_records
group by employee_name
order by total_mistakes desc
)
SELECT
    employee_name,
    total_mistakes
FROM error_count
WHERE total_mistakes > (
    SELECT AVG(total_mistakes)
    FROM error_count
);




-- creating VIEW for the long query above 
 CREATE VIEW Incorrect_records AS (
 SELECT
 auditor_report.location_id,
 visits.record_id,
 employee.employee_name,
 auditor_report.true_water_source_score AS auditor_score,
 wq.subjective_quality_score AS surveyor_score,
 auditor_report.statements AS statements
 FROM
 auditor_report
 JOIN
 visits
 ON auditor_report.location_id = visits.location_id
 JOIN
 water_quality AS wq
 ON visits.record_id = wq.record_id
 JOIN
 employee
 ON employee.assigned_employee_id = visits.assigned_employee_id
 WHERE
 visits.visit_count =1
 AND auditor_report.true_water_source_score != wq.subjective_quality_score);
 
 select *
 from Incorrect_records;
    
-- creating error_count CTE     
 WITH error_count AS (-- This CTE calculates the number of mistakes each employee made
 SELECT
 employee_name,
 COUNT(employee_name) AS number_of_mistakes
 FROM
 Incorrect_records
 /* Incorrect_records is a view that joins the audit report to the database
 GROUP BY
 for records where the auditor and
 employees scores are different*/
group by employee_name)
 -- Query
 SELECT * FROM error_count
 order by number_of_mistakes desc;
 
 
 -- CALCULATING THE AVERAGE MISTAKES
 WITH error_count AS (-- This CTE calculates the number of mistakes each employee made
 SELECT
 employee_name,
 COUNT(employee_name) AS number_of_mistakes
 FROM
 Incorrect_records
 /* Incorrect_records is a view that joins the audit report to the database
 GROUP BY
 for records where the auditor and
 employees scores are different*/
group by employee_name),

-- CREATING suspect_list CTE
suspect_list AS(
SELECT
    employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes)
    FROM error_count)
)
-- FISHING OUT CORRUPT SURVEYORS
SELECT 
    employee_name,
    location_id,
    statements
FROM
    Incorrect_records
WHERE
    employee_name IN (SELECT employee_name FROM suspect_list)
-- filtering for the statemets that had cash in it
    AND statements LIKE '%cash%'
ORDER BY
    employee_name;
    
    



    
    
    