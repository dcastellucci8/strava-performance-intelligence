-- Query 1: Top 5 Hottest Runs
-- WHAT: Finds the 5 runs recorded in the highest temperature conditions
-- HOW: Joins STRAVA_ACTIVITIES to WEATHER_DATA on activity ID, filters to 
--      runs only, and orders by temperature descending with a LIMIT of 5
-- WHY: Surfaces extreme condition data for Strava Wrapped-style engagement 
--      features and conditions intelligence
-- OUTPUT: Top result was a run on 2022-08-24 at 99.2°F — a 3.6 mile run 
--         in Las Vegas. All top 5 were summer runs between 87-99°F.

SELECT 
    a.NAME,
    a.START_DATE_LOCAL,
    a.DISTANCE/1609.34 AS DISTANCE_MILES,
    a.MOVING_TIME/60 AS MOVING_TIME_MINUTES,
    w.TEMPERATURE,
    w.FEELS_LIKE,
    w.HUMIDITY
FROM STRAVA_ACTIVITIES a
JOIN WEATHER_DATA w ON a.ID = w.ID
WHERE a.TYPE = 'Run'
ORDER BY w.TEMPERATURE DESC
LIMIT 5;

-- Query 2: Top 5 Coldest Runs
-- WHAT: Finds the 5 runs recorded in the coldest temperature conditions
-- HOW: Joins STRAVA_ACTIVITIES to WEATHER_DATA on activity ID, filters to
--      runs only, and orders by temperature ascending with a LIMIT of 5
-- WHY: Surfaces extreme cold condition data for Strava Wrapped-style 
--      engagement features and conditions intelligence
-- OUTPUT: Top result was a run on 2022-02-04 at -0.8°F with a feels like
--         of -11.1°F. All top 5 were winter runs in January-February 2022,
--         ranging from -0.8°F to 6.9°F.

SELECT 
    a.NAME,
    a.START_DATE_LOCAL,
    a.DISTANCE/1609.34 AS DISTANCE_MILES,
    a.MOVING_TIME/60 AS MOVING_TIME_MINUTES,
    w.TEMPERATURE,
    w.FEELS_LIKE,
    w.HUMIDITY
FROM STRAVA_ACTIVITIES a
JOIN WEATHER_DATA w ON a.ID = w.ID
WHERE a.TYPE = 'Run'
ORDER BY w.TEMPERATURE ASC
LIMIT 5;

-- Query 3: Top 5 Windiest Runs
-- WHAT: Finds the 5 runs recorded in the highest wind speed conditions
-- HOW: Joins STRAVA_ACTIVITIES to WEATHER_DATA on activity ID, filters to
--      runs only, and orders by wind speed descending with a LIMIT of 5
-- WHY: Wind is an underreported performance factor — surfaces extreme 
--      condition data for Strava Wrapped-style engagement features
-- OUTPUT: Top result was a run on 2024-11-05 at 23.2 mph winds. All top 5
--         ranged from 21.2 to 23.2 mph, occurring across all seasons.

SELECT 
    a.NAME,
    a.START_DATE_LOCAL,
    a.DISTANCE/1609.34 AS DISTANCE_MILES,
    a.MOVING_TIME/60 AS MOVING_TIME_MINUTES,
    w.WIND_SPEED,
    w.TEMPERATURE
FROM STRAVA_ACTIVITIES a
JOIN WEATHER_DATA w ON a.ID = w.ID
WHERE a.TYPE = 'Run'
ORDER BY w.WIND_SPEED DESC
LIMIT 5;

-- Query 4: Average Pace and Heart Rate by Temperature Bucket
-- WHAT: Calculates average pace and heart rate across meaningful temperature ranges
-- HOW: Joins STRAVA_ACTIVITIES to WEATHER_DATA, uses CASE statement to bucket
--      temperatures into runner-relevant ranges, then groups by bucket
-- WHY: Tests whether temperature meaningfully impacts performance metrics.
--      Supports the conditions intelligence product pitch.
-- OUTPUT: Ideal conditions (50-70°F) showed the lowest avg HR at 144.7 BPM.
--         Both extremes showed elevated HR — below freezing at 148.4 BPM and
--         hot (90°F+) at 150.6 BPM, though the hot bucket only had 3 runs.
--         Pace was relatively consistent across buckets (8.18-8.41 min/mile),
--         suggesting effort rather than speed explains the HR variation.

SELECT 
    CASE 
        WHEN w.TEMPERATURE < 32 THEN '1. Below Freezing (<32°F)'
        WHEN w.TEMPERATURE BETWEEN 32 AND 50 THEN '2. Cold (32-50°F)'
        WHEN w.TEMPERATURE BETWEEN 50 AND 70 THEN '3. Ideal (50-70°F)'
        WHEN w.TEMPERATURE BETWEEN 70 AND 90 THEN '4. Warm (70-90°F)'
        ELSE '5. Hot (90°F+)'
    END AS TEMP_BUCKET,
    COUNT(*) AS RUN_COUNT,
    ROUND(AVG((a.MOVING_TIME/60.0) / (a.DISTANCE/1609.34)), 2) AS AVG_PACE_MIN_PER_MILE,
    ROUND(AVG(a.AVERAGE_HEARTRATE), 1) AS AVG_HEART_RATE
FROM STRAVA_ACTIVITIES a
JOIN WEATHER_DATA w ON a.ID = w.ID
WHERE a.TYPE = 'Run'
    AND a.AVERAGE_HEARTRATE IS NOT NULL
    AND a.DISTANCE > 0
GROUP BY TEMP_BUCKET
ORDER BY TEMP_BUCKET;

-- Query 5: Annual Running Volume Summary
-- WHAT: Calculates total miles, total runs, and average weekly mileage per year
-- HOW: Extracts year from START_DATE_LOCAL, groups by year, aggregates distance
--      and activity count, calculates weekly average by dividing by 52
-- WHY: Shows training volume trends over time — sets up the injury prevention
--      narrative by establishing baseline training load by year
-- OUTPUT: Peak volume year was 2022 at 2,300 miles (44.2 avg weekly miles).
--         2024 was the lowest at 610 miles.
--         Avg miles per run dropped from 6.62 in 2018 to 4.92 in 2024,
--         suggesting shorter recovery runs during low volume periods.
--         2018 and 2026 are partial years and should be interpreted with caution.

SELECT 
    YEAR(TO_TIMESTAMP(START_DATE_LOCAL)) AS ACTIVITY_YEAR,
    COUNT(*) AS TOTAL_RUNS,
    ROUND(SUM(DISTANCE/1609.34), 1) AS TOTAL_MILES,
    ROUND(AVG(DISTANCE/1609.34), 2) AS AVG_MILES_PER_RUN,
    ROUND(SUM(DISTANCE/1609.34) / 52, 1) AS AVG_WEEKLY_MILES
FROM STRAVA_ACTIVITIES
WHERE TYPE = 'Run'
GROUP BY ACTIVITY_YEAR
ORDER BY ACTIVITY_YEAR;

-- Query 6: Average Pace by Effort Level and Year
-- WHAT: Breaks runs into pace bins by year to show progression across effort levels
-- HOW: Uses CASE statement to bin runs into Sub 7:00, 7:00-8:30, and 8:30+
--      pace categories, then groups by year and bin. Filters applied to exclude
--      manual entries and impossible paces.
-- WHY: Removes the distortion of mixing easy and hard runs in a single average.
--      Shows whether workout pace and easy pace have improved independently.
-- OUTPUT: Sub 7:00 runs peaked in 2019 (53 runs) and have declined since,
--         reflecting a shift toward higher volume easier training.
--         The 8:30+ bucket grew significantly in 2024-2025 consistent with
--         injury recovery and treadmill incline work.
--         2025 showed 171 runs in the 7:00-8:30 bucket — the highest of any
--         year — suggesting a high volume base building year.

SELECT 
    YEAR(TO_TIMESTAMP(START_DATE_LOCAL)) AS ACTIVITY_YEAR,
    CASE 
        WHEN (MOVING_TIME / 60.0) / (DISTANCE / 1609.34) < 7 THEN '1. Sub 7:00'
        WHEN (MOVING_TIME / 60.0) / (DISTANCE / 1609.34) < 8.5 THEN '2. 7:00-8:30'
        ELSE '3. 8:30+'
    END AS PACE_BUCKET,
    COUNT(*) AS RUN_COUNT,
    ROUND(AVG((MOVING_TIME / 60.0) / (DISTANCE / 1609.34)), 2) AS AVG_PACE
FROM STRAVA_ACTIVITIES
WHERE TYPE = 'Run'
    AND DISTANCE / 1609.34 >= 0.5
    AND MOVING_TIME / 60 >= 5
    AND (MOVING_TIME / 60.0) / (DISTANCE / 1609.34) BETWEEN 4 AND 20
GROUP BY ACTIVITY_YEAR, PACE_BUCKET
ORDER BY ACTIVITY_YEAR, PACE_BUCKET;

-- Query 7: Top Kudos Activities Ranked Within Each Year
-- WHAT: Ranks each activity by kudos count within its year
-- HOW: Uses RANK() window function partitioned by year and ordered by
--      kudos count descending to identify top performing posts each year
-- WHY: Shows which activities drove the most engagement each year —
--      supports the engagement intelligence product pitch
-- OUTPUT: Top kudos activities are almost exclusively marathons and major races.
--         All time high was "Grateful Grateful Grateful" (2022) at 95 kudos.
--         "Execute. Compete." (2025 Chicago Marathon) ranked 2nd at 84 kudos.
--         Race activities consistently outperform all other activity types
--         for engagement — strongly supports WORKOUT_Race as a key model feature.

SELECT 
    YEAR(TO_TIMESTAMP(START_DATE_LOCAL)) AS ACTIVITY_YEAR,
    NAME,
    KUDOS_COUNT,
    DISTANCE / 1609.34 AS DISTANCE_MILES,
    RANK() OVER (PARTITION BY YEAR(TO_TIMESTAMP(START_DATE_LOCAL)) 
                 ORDER BY KUDOS_COUNT DESC) AS KUDOS_RANK
FROM STRAVA_ACTIVITIES
WHERE TYPE = 'Run'
    AND DISTANCE / 1609.34 >= 0.5
    AND MOVING_TIME / 60 >= 5
QUALIFY KUDOS_RANK <= 3
ORDER BY KUDOS_COUNT DESC;

-- Query 8: Running Streaks Over 10 Days
-- WHAT: Identifies all consecutive day running streaks longer than 10 days
-- HOW: Uses LAG window function to compare each run date to the prior run date,
--      flags consecutive days, then groups into streaks. HAVING clause filters
--      to only streaks over 10 days.
-- WHY: Streak data is a powerful engagement mechanic — Strava could use this
--      to notify athletes when they are close to a personal streak record
-- OUTPUT: 18 streaks over 10 days identified across 7 years.
--         Longest streak was 19 days (2019-08-04 to 2019-08-22).
--         Three streaks of 16+ days, all in 2018-2019 peak training years.
--         Notable streak of 12 days in Sept 2025 during Chicago Marathon buildup.
--         Streak mechanic is a natural Strava engagement feature --
--         athletes could be notified when approaching a personal streak record.

WITH daily_runs AS (
    SELECT DISTINCT 
        DATE(TO_TIMESTAMP(START_DATE_LOCAL)) AS RUN_DATE
    FROM STRAVA_ACTIVITIES
    WHERE TYPE = 'Run'
        AND DISTANCE / 1609.34 >= 0.5
        AND MOVING_TIME / 60 >= 5
),
streak_groups AS (
    SELECT 
        RUN_DATE,
        DATEADD(day, -ROW_NUMBER() OVER (ORDER BY RUN_DATE), RUN_DATE) AS STREAK_GROUP
    FROM daily_runs
)
SELECT 
    MIN(RUN_DATE) AS STREAK_START,
    MAX(RUN_DATE) AS STREAK_END,
    COUNT(*) AS STREAK_LENGTH_DAYS
FROM streak_groups
GROUP BY STREAK_GROUP
HAVING COUNT(*) > 9
ORDER BY STREAK_LENGTH_DAYS DESC;

-- Query 9: Average Kudos by Workout Category
-- WHAT: Calculates average kudos, comment count, and activity count by workout type
-- HOW: Groups activities by WORKOUT_TYPE, maps to readable labels using CASE,
--      aggregates kudos and comments. No join needed -- engagement data lives
--      entirely in STRAVA_ACTIVITIES
-- WHY: Tests whether workout type drives engagement -- supports feature selection
--      for the kudos prediction model
-- OUTPUT: Race activities drove the highest engagement by far with 29.13 avg kudos
--         and 2.76 avg comments, nearly double Long Run (15.91 kudos).
--         Workout and Default categories trailed significantly.
--         Strongly confirms WORKOUT_Race as a top feature in the kudos model.

SELECT 
  CASE WORKOUT_TYPE
        WHEN 1 THEN 'Race'
        WHEN 2 THEN 'Long Run'
        WHEN 3 THEN 'Workout'
        ELSE 'Default'
    END AS WORKOUT_CATEGORY,
    COUNT(*) AS ACTIVITY_COUNT,
    ROUND(AVG(KUDOS_COUNT), 2) AS AVG_KUDOS,
    ROUND(AVG(COMMENT_COUNT), 2) AS AVG_COMMENTS
FROM STRAVA_ACTIVITIES
WHERE TYPE = 'Run'
    AND DISTANCE / 1609.34 >= 0.5
    AND MOVING_TIME / 60 >= 5
GROUP BY WORKOUT_CATEGORY
ORDER BY AVG_KUDOS DESC;

-- Query 10: Average Kudos by Day of Week
-- WHAT: Calculates average kudos and activity count by day of week
-- HOW: Extracts day of week from START_DATE_LOCAL, groups by day,
--      aggregates kudos count. No join needed.
-- WHY: Tests whether posting day drives engagement -- supports feature
--      selection for the kudos prediction model. If certain days drive
--      more kudos, Strava could prompt athletes to share on high-engagement days.
-- OUTPUT: Weekend runs drive significantly higher engagement than weekdays.
--         Saturday highest at 11.18 avg kudos, Sunday second at 10.49.
--         Weekdays ranged from 6.50 (Tuesday) to 8.56 (Wednesday).
--         Wednesday outlier likely driven by mid-week long runs or workouts.
--         Day of week confirmed as a relevant feature for the kudos model,
--         though effect size is smaller than race type or distance.

SELECT 
    DAYNAME(TO_TIMESTAMP(START_DATE_LOCAL)) AS DAY_OF_WEEK,
    DAYOFWEEK(TO_TIMESTAMP(START_DATE_LOCAL)) AS DAY_NUM,
    COUNT(*) AS ACTIVITY_COUNT,
    ROUND(AVG(KUDOS_COUNT), 2) AS AVG_KUDOS,
    ROUND(AVG(COMMENT_COUNT), 2) AS AVG_COMMENTS
FROM STRAVA_ACTIVITIES
WHERE TYPE = 'Run'
    AND DISTANCE / 1609.34 >= 0.5
    AND MOVING_TIME / 60 >= 5
GROUP BY DAY_OF_WEEK, DAY_NUM
ORDER BY DAY_NUM;

-- Query 11: Longest Breaks from Running vs Average Gap
-- WHAT: Identifies all running gaps longer than your average gap between runs
-- HOW: Uses LAG window function to calculate days between consecutive runs,
--      then a subquery calculates your average gap length. Outer query returns
--      only gaps exceeding that average.
-- WHY: Long breaks are a key injury risk signal -- returning from extended
--      rest requires careful load management. Supports the ACWR product pitch.
-- OUTPUT: Average gap between runs is just 1.3 days, highlighting how
--         consistent training is the norm. Two longest gaps were 54 days
--         (Apr-Jun 2024) and 49 days (Jan-Feb 2024), both injury related.
--         Row 13 shows a 12 day gap in Jul-Aug 2025 consistent with the
--         mid-year injury. Long gaps directly feed the ACWR Calibrating flag
--         logic -- exactly the return-to-training window where guidance matters most.

WITH run_gaps AS (
    SELECT 
        DATE(TO_TIMESTAMP(START_DATE_LOCAL)) AS RUN_DATE,
        LAG(DATE(TO_TIMESTAMP(START_DATE_LOCAL))) OVER (ORDER BY START_DATE_LOCAL) AS PRIOR_RUN_DATE,
        DATEDIFF(day, 
            LAG(DATE(TO_TIMESTAMP(START_DATE_LOCAL))) OVER (ORDER BY START_DATE_LOCAL),
            DATE(TO_TIMESTAMP(START_DATE_LOCAL))
        ) AS DAYS_SINCE_LAST_RUN
    FROM STRAVA_ACTIVITIES
    WHERE TYPE = 'Run'
        AND DISTANCE / 1609.34 >= 0.5
        AND MOVING_TIME / 60 >= 5
)
SELECT 
    PRIOR_RUN_DATE AS GAP_START,
    RUN_DATE AS GAP_END,
    DAYS_SINCE_LAST_RUN,
    ROUND((SELECT AVG(DAYS_SINCE_LAST_RUN) FROM run_gaps WHERE DAYS_SINCE_LAST_RUN IS NOT NULL), 1) AS AVG_GAP_DAYS
FROM run_gaps
WHERE DAYS_SINCE_LAST_RUN > (
    SELECT AVG(DAYS_SINCE_LAST_RUN) 
    FROM run_gaps 
    WHERE DAYS_SINCE_LAST_RUN IS NOT NULL
)
ORDER BY DAYS_SINCE_LAST_RUN DESC
LIMIT 15;