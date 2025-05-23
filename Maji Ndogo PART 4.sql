-- All of the information about the location of a water source is in the location table, specifically the town and province of that water source
SELECT 
    loc.province_name,
    loc.town_name,
    loc.location_type,
    vis.source_id,
    vis.time_in_queue,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM
    location loc
        JOIN
    visits vis ON loc.location_id = vis.location_id
        JOIN
    water_source ws ON vis.source_id = ws.source_id
        JOIN
    well_pollution AS wp ON ws.source_id = wp.source_id
WHERE
    vis.visit_count = 1;
    
    
 -- This table assembles data from different tables into one to simplify analysis
 SELECT
 water_source.type_of_water_source,
 location.town_name,
 location.province_name,
 location.location_type,
 water_source.number_of_people_served,
 visits.time_in_queue,
 well_pollution.results
 FROM
 visits
 LEFT JOIN
 well_pollution
 ON well_pollution.source_id = visits.source_id
 INNER JOIN
 location
 ON location.location_id = visits.location_id
 INNER JOIN
 water_source
 ON water_source.source_id = visits.source_id
 WHERE
 visits.visit_count = 1;
 
 
  CREATE VIEW combined_analysis_table AS
    SELECT 
        water_source.type_of_water_source AS source_type,
        location.town_name,
        location.province_name,
        location.location_type,
        water_source.number_of_people_served AS people_served,
        visits.time_in_queue,
        well_pollution.results
    FROM
        visits
            LEFT JOIN
        well_pollution ON well_pollution.source_id = visits.source_id
            INNER JOIN
        location ON location.location_id = visits.location_id
            INNER JOIN
        water_source ON water_source.source_id = visits.source_id
    WHERE
        visits.visit_count = 1;
	
SELECT 
    COUNT(*)
FROM
    combined_analysis_table;
    
--  province_totals is a CTE that calculates the sum of all the people surveyed grouped by province. 
WITH province_totals AS (-- This CTE calculates the population of each province
 SELECT
 province_name,
 SUM(people_served) AS total_ppl_serv
 FROM
 combined_analysis_table
 GROUP BY
 province_name
 )
 SELECT
 ct.province_name,
 -- These case statements create columns for each type of source.
 -- The results are aggregated and percentages are calculated
 ROUND((SUM(CASE WHEN source_type = 'river' THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
 ROUND((SUM(CASE WHEN source_type = 'shared_tap' THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
 ROUND((SUM(CASE WHEN source_type = 'tap_in_home' THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
 ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken' THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
 ROUND((SUM(CASE WHEN source_type = 'well' THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
 FROM
 combined_analysis_table ct
 JOIN
 province_totals pt ON ct.province_name = pt.province_name
 GROUP BY
 ct.province_name
 ORDER BY
 ct.province_name;
 
 
 CREATE TEMPORARY TABLE town_aggregated_water_access
 WITH town_totals AS (-- This CTE calculates the population of each town 
 -- Since there are two Harare towns, we have to group by province_name and town_name
 SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
 FROM combined_analysis_table
 GROUP BY province_name,town_name
 )
 SELECT
 ct.province_name,
 ct.town_name,
 ROUND((SUM(CASE WHEN source_type = 'river'
 THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
 ROUND((SUM(CASE WHEN source_type = 'shared_tap'
 THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
 ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
 THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
 ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
 THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
 ROUND((SUM(CASE WHEN source_type = 'well'
 THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
 FROM
 combined_analysis_table ct
 JOIN 
 -- Since the town names are not unique, we have to join on a composite key
 town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
 GROUP BY 
 -- We group by province first, then by town.
 ct.province_name,
 ct.town_name
 ORDER BY
 ct.town_name;
 
 select *
 from town_aggregated_water_access
 order by river DESC;


 select *
 from town_aggregated_water_access
 where town_name = 'Amina'
 order by province_name DESC;
 
  SELECT 
    province_name,
    town_name,
    ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100, 0) AS Pct_broken_taps
FROM
    town_aggregated_water_access;
    
    
CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY,
    source_id VARCHAR(20) NOT NULL REFERENCES water_source (source_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50),
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog' , 'In progress', 'Complete')),
    Date_of_completion DATE,
    Comments TEXT
);


    
-- Project_progress_query
 SELECT 
    CASE
        WHEN water_source.type_of_water_source = 'river' THEN 'Drill wells'
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'RO filter'
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN
            water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
        THEN
            CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
		when water_source.type_of_water_source = 'tap_in_home_broken' then 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement,
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
        AND (well_pollution.description != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken' , 'river')
        OR (water_source.type_of_water_source = 'shared_tap'
        AND visits.time_in_queue >= 30));
        
        




  select *  from well_pollution;
  
  
  
  
  