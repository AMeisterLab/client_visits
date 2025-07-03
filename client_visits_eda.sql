-- Vists by date
SELECT *
FROM visits_by_date;

-- Client visits
SELECT *
FROM client_visits;

-- New Households by Date
SELECT first_visit, COUNT(*) AS new_households
FROM client_visits
GROUP BY first_visit
ORDER BY first_visit ASC;

-- Number of clients and visits
SELECT num_visits, COUNT(*) AS num_clients
FROM client_visits
GROUP BY num_visits
ORDER BY num_visits ASC;

-- Clients by Language
WITH lang_cte AS 
(
SELECT DISTINCT id, `language`
FROM clients_staging
WHERE status = 'Active'
)
SELECT `language`, COUNT(*) as num_clients
FROM lang_cte
GROUP BY `language`
ORDER BY num_clients DESC;

-- Clients by Zip Cde
WITH zip_cte AS 
(
SELECT DISTINCT id, zip
FROM clients_staging
)
SELECT zip, COUNT(*) as num_clients
FROM zip_cte
GROUP BY zip
ORDER BY num_clients DESC;

-- Number of clients arrived before start
SELECT visit_date, COUNT(DISTINCT client_id) AS num_clients
FROM visits_staging
WHERE (
	DAYNAME(visit_date) = 'Tuesday' AND visit_time_corrected < '16:00:00')
    OR (
    DAYNAME(visit_date) IN ('Thursday', 'Saturday') AND visit_time_corrected < '09:30:00')
GROUP BY visit_date
ORDER BY visit_date;

-- Average number of clinets arrived before start by day of week
with all_visits AS (
	SELECT 
		visit_date,
        DAYNAME(visit_date) as day_name,
        COUNT(DISTINCT client_id) as total_clients
	FROM visits_staging
    WHERE DAYNAME(visit_date) IN ('Tuesday', 'Thursday', 'Saturday')
    GROUP BY visit_date
),
 early_visits AS (
	SELECT 
		visit_date,
        DAYNAME(visit_date) as day_name,
		COUNT(DISTINCT client_id) AS early_clients
	FROM visits_staging
	WHERE (
		DAYNAME(visit_date) = 'Tuesday' AND visit_time_corrected < '16:00:00')
		OR (
		DAYNAME(visit_date) IN ('Thursday', 'Saturday') AND visit_time_corrected < '09:30:00')
	GROUP BY visit_date
),
combined AS (
	SELECT
		all_visits.visit_date,
        all_visits.day_name,
        all_visits.total_clients,
        COALESCE(early_visits.early_clients, 0) AS early_clients
	FROM all_visits
    LEFT JOIN early_visits
		ON all_visits.visit_date = early_visits.visit_date
)
SELECT 
	day_name, 
	ROUND(AVG(total_clients)) as avg_total_clients,
    ROUND(AVG(early_clients)) as avg_clients_before_start,
    ROUND((AVG(early_clients)/AVG(total_clients))*100,1) as percent_of_total
FROM combined
GROUP BY day_name;

-- Representative visit dates for wait time analysis
SELECT * 
FROM visits_staging
WHERE visit_date IN ('2025-03-15'); -- ('2025-03-13', '2025-03-15');

-- Language by visit date
SELECT
  visit_date,
  SUM(language = 'Spanish') AS Spanish,
  SUM(language = 'English') AS English,
  SUM(language = 'Chinese') AS Chinese,
  SUM(language = 'Vietnamese') AS Vietnamese,
  SUM(language = 'Ukrainian') AS Ukrainian,
  SUM(language = 'Russian') AS Russian,
  SUM(language = 'Persian') AS Persian,
  SUM(language = 'Other') AS Other,
  SUM(language = 'Unknown') AS 'Unknown',
  SUM(language = 'Arabic') AS Arabic,
  SUM(language = 'Lao') AS Lao,
  SUM(language = 'Filipino') AS Filipino,
  SUM(language = 'Haitian Creole') AS Haitian_Creole,
  SUM(language = 'Romanian') AS Romanian,
  SUM(language = 'Korean') AS Korean,
  SUM(language = 'Portuguese') AS Portuguese,
  SUM(language != '') AS total
FROM visits_staging
GROUP BY visit_date
ORDER BY visit_date;

-- Average visits by month
with months AS (
	SELECT 
		visit_date,
        MONTH(visit_date) as month_num,
        COUNT(DISTINCT client_id) as total_clients
	FROM visits_staging
    GROUP BY visit_date
)
SELECT 
	month_num, 
	ROUND(AVG(total_clients),2) as avg_total_clients,
    COUNT(visit_date) as distributions,
    SUM(total_clients) total_clients
FROM months
GROUP BY month_num;

