-- Data Cleaning

-- Create staging database
	DROP TABLE visits_staging; 

	CREATE TABLE visits_staging 
	LIKE visits;

	INSERT visits_staging
	SELECT *
	FROM visits;

	SELECT *
	FROM visits_staging;

-- Remove Duplicates if there are any
	WITH duplicate_cte AS (
	SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY visit_datetime, visit_type, client_name, client_account, dob, zip_code, language) AS row_num
	FROM visits_staging)
	SELECT *
	FROM duplicate_cte
	WHERE row_num > 1;

-- Split vist_datetime to visit_date column
	ALTER TABLE visits_staging
	ADD COLUMN visit_date DATE;
	
    UPDATE visits_staging 
	SET visit_date = SUBSTRING_INDEX(visit_datetime, ";", 1);

-- Create visit_time column and a corrected column that subtracts 1 hour to accomodate Software Reporting issue   
    ALTER TABLE visits_staging
	ADD COLUMN  visit_time TEXT;
	
    UPDATE visits_staging 
	SET visit_time = TRIM(SUBSTRING_INDEX(visit_datetime, ";", -1));
    
	ALTER TABLE visits_staging
	ADD COLUMN  visit_time_corrected TEXT;
    
	UPDATE visits_staging 
	SET visit_time_corrected = left(visit_time, (length(visit_time)-2));
    
    UPDATE visist_staging
    SET visit_time_corrected = STR_TO_DATE(visit_time_corrected, '%h:%i');
    
	ALTER TABLE visits_staging
    MODIFY COLUMN visit_time_corrected TIME;
    
    UPDATE visits_staging
    SET visit_time_corrected = SUBTIME(visit_time_corrected, '1:0:0');
    
-- Remove leading comma and space from client name
	UPDATE visits_staging
	SET client_name = TRIM(SUBSTRING(client_name, 3));

-- Clean up bad dates (example 0075-03-01)
    SELECT *,  CONCAT(SUBSTRING(dob,6,2),'/',SUBSTRING(dob,9,2),'/19',SUBSTRING(dob ,3,2))
    FROM visits_staging
    WHERE dob Like '00%';
    
    UPDATE visits_staging
    SET dob =  CONCAT(SUBSTRING(dob,6,2),'/',SUBSTRING(dob,9,2),'/19',SUBSTRING(dob ,3,2))
    WHERE dob Like '00%';
    
-- Change dob format to date

    UPDATE visits_staging
	SET dob = STR_TO_DATE(dob, '%m/%d/%Y'); 
    
    ALTER TABLE visits_staging
    MODIFY COLUMN dob DATE;

-- Standardize zip_codes to 5 digits
	UPDATE visits_staging
	SET zip_code = LEFT(zip_code, 5)
	WHERE LENGTH(zip_code) > 5;
    
	UPDATE visits_staging
	SET zip_code = '99999'
	WHERE LENGTH(zip_code) < 5;
    
	SELECT DISTINCT zip_code
	from visits_staging
	ORDER BY zip_code asc;

-- Check for null values and update if needed
	SELECT * 
	FROM visits_staging
	WHERE client_name IS NULL or client_name = '';

	SELECT * 
	FROM visits_staging
	WHERE client_account IS NULL or client_account = '';

	SELECT * 
	FROM visits_staging
	WHERE dob IS NULL;

	SELECT * 
	FROM visits_staging
	WHERE zip_code IS NULL or zip_code = '';

	SELECT * 
	FROM visits_staging
	WHERE `language` IS NULL or `language` = ''; 

	UPDATE visits_staging
	SET `language` = 'Unknown'
	WHERE `language` IS NULL or `language` = '';

	SELECT * 
	FROM visits_staging
	WHERE visit_date IS NULL;

	SELECT * 
	FROM visits_staging
	WHERE visit_time IS NULL;

-- Remove unecessary columns
ALTER TABLE visits_staging
DROP COLUMN visit_datetime,
DROP COLUMN visit_type;

ALTER TABLE visits_staging
DROP COLUMN client_name;

-- Look at cleaned table
SELECT *
FROM visits_staging;

