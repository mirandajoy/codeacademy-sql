/* 1a. There is data provided from Dec 2016 - March 2017. It will be possible to calculate churn for Jan 2017 - March 2017. */

SELECT MIN(subscription_start), 
MAX (subscription_start)
FROM subscriptions;


/* 1b. There are 2 different segements, 87 and 30 */

SELECT *
from subscriptions
LIMIT 100;


/* 2 Churn has been increasing. Jan 16.1% / Feb 18.9% / Mar 27.4% */

WITH months AS (
	SELECT 
	  '2017-01-01' as first_day,
    '2017-01-31' as last_day
  UNION
  SELECT
   '2017-02-01' as first_day,
   '2017-02-28' as last_day
  UNION
  SELECT
   '2017-03-01' as first_day,
   '2017-03-31' as last_day
), 
cross_join AS (
	SELECT subscriptions.*, months.*
  FROM subscriptions
  CROSS JOIN months
), 
status AS (
	SELECT id, first_day as month, 
  CASE
  	WHEN (subscription_start < first_day)
  		AND (
     	subscription_end > first_day
     	OR subscription_end IS NULL
     ) THEN 1
  	ELSE 0
  END as is_active,
  CASE
 	  WHEN subscription_end BETWEEN first_day AND last_day THEN 1
 	  ELSE 0
  END as is_canceled
FROM cross_join),
status_aggregate AS 
(SELECT month,
  SUM(is_active) as active,
  SUM(is_canceled) as canceled
  FROM status
  GROUP BY 1
)
SELECT
  month,
  1.0 * canceled/active as monthly_churn
FROM status_aggregate;

/* 3 Churn rates are lower each month for segment 30. */

WITH months AS (
  SELECT 
 		'2017-01-01' as first_day,
   	'2017-01-31' as last_day
  UNION
  SELECT
    '2017-02-01' as first_day,
    '2017-02-28' as last_day
  UNION
  SELECT
    '2017-03-01' as first_day,
    '2017-03-31' as last_day
), 
cross_join AS (
	SELECT subscriptions.*, months.*
  FROM subscriptions
  CROSS JOIN months
), 
status AS (
	SELECT id, first_day as month, 
  CASE
 	  WHEN (subscription_start < first_day)
 		  AND (
      	subscription_end > first_day
      	OR subscription_end IS NULL
      ) 
 		  AND segment = 87
 		  THEN 1
 	  ELSE 0
  END as is_active_87,
  CASE
 	  WHEN (subscription_start < first_day)
 		  AND (
      	subscription_end > first_day
      	OR subscription_end IS NULL
      ) 
 		  AND segment = 30
 		  THEN 1
 	  ELSE 0
  END as is_active_30,
  CASE
  	WHEN subscription_end BETWEEN first_day AND last_day
  		AND segment = 87
  		THEN 1
  	ELSE 0
  END as is_canceled_87,
  CASE
  	WHEN subscription_end BETWEEN first_day AND last_day
  		AND segment = 30
  		THEN 1
  	ELSE 0
  END as is_canceled_30
FROM cross_join),
status_aggregate AS (
	SELECT month,
    SUM(is_active_87) as sum_active_87,
    SUM(is_active_30) as sum_active_30,
    SUM(is_canceled_87) as sum_canceled_87,
    SUM(is_canceled_30) as sum_canceled_30
  FROM status
  GROUP BY 1
)
SELECT month,
  1.0 * sum_canceled_87/sum_active_87 as churn_87,
  1.0 * sum_canceled_30/sum_active_30 as churn_30
FROM status_aggregate;