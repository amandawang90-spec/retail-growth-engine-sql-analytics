
CREATE TABLE harvey_stg_weather_daily as
WITH daily_raw AS (
    SELECT airport_code,
           station_id,
           JSON_ARRAY_ELEMENTS(extracted_data -> 'data') AS json_data
    FROM harvey_weather_daily_raw_data_check
),
daily_flattened AS (
    SELECT airport_code,
           station_id,
           (json_data ->> 'date')::DATE AS date,
           (json_data ->> 'tavg')::NUMERIC AS avg_temp_c,
           (json_data ->> 'tmin')::NUMERIC AS min_temp_c,
           (json_data ->> 'tmax')::NUMERIC AS max_temp_c,
           (json_data ->> 'prcp')::NUMERIC AS precipitation_mm,
           (json_data ->> 'snow')::NUMERIC::INTEGER AS max_snow_mm,
           (json_data ->> 'wdir')::NUMERIC::INTEGER AS avg_wind_direction,
           (json_data ->> 'wspd')::NUMERIC AS avg_wind_speed_kmh,
           (json_data ->> 'wpgt')::NUMERIC AS wind_peakgust_kmh,
           (json_data ->> 'pres')::NUMERIC AS avg_pressure_hpa,
           (json_data ->> 'tsun')::NUMERIC::INTEGER AS sun_minutes
    FROM daily_raw
)
SELECT *
FROM daily_flattened
WHERE date BETWEEN '2017-07-28' AND '2017-09-28'


CREATE TABLE harvey_stg_weather_daily as

WITH daily_raw AS (
    SELECT airport_code,
           station_id,
           JSON_ARRAY_ELEMENTS(extracted_data -> 'data') AS json_data
    FROM harvey_weather_daily_raw_data
),
daily_flattened AS (
    SELECT airport_code,
           station_id,
           (json_data ->> 'date')::DATE AS date,
           (json_data ->> 'tavg')::NUMERIC AS avg_temp_c,
           (json_data ->> 'tmin')::NUMERIC AS min_temp_c,
           (json_data ->> 'tmax')::NUMERIC AS max_temp_c,
           (json_data ->> 'prcp')::NUMERIC AS precipitation_mm,
           (json_data ->> 'snow')::NUMERIC::INTEGER AS max_snow_mm,
           (json_data ->> 'wdir')::NUMERIC::INTEGER AS avg_wind_direction,
           (json_data ->> 'wspd')::NUMERIC AS avg_wind_speed_kmh,
           (json_data ->> 'wpgt')::NUMERIC AS wind_peakgust_kmh,
           (json_data ->> 'pres')::NUMERIC AS avg_pressure_hpa,
           (json_data ->> 'tsun')::NUMERIC::INTEGER AS sun_minutes
    FROM daily_raw
)
SELECT *
FROM daily_flattened
WHERE date BETWEEN '2017-07-28' AND '2017-09-28'

WITH daily_raw AS (
    SELECT airport_code,
           station_id,
           JSON_ARRAY_ELEMENTS(extracted_data -> 'data') AS json_data
    FROM harvey_weather_daily_raw
),
daily_flattened AS (
    SELECT airport_code,
           station_id,
           (json_data ->> 'date')::DATE AS date,
           (json_data ->> 'tavg')::NUMERIC AS avg_temp_c,
           (json_data ->> 'tmin')::NUMERIC AS min_temp_c,
           (json_data ->> 'tmax')::NUMERIC AS max_temp_c,
           (json_data ->> 'prcp')::NUMERIC AS precipitation_mm,
           (json_data ->> 'snow')::NUMERIC::INTEGER AS max_snow_mm,
           (json_data ->> 'wdir')::NUMERIC::INTEGER AS avg_wind_direction,
           (json_data ->> 'wspd')::NUMERIC AS avg_wind_speed_kmh,
           (json_data ->> 'wpgt')::NUMERIC AS wind_peakgust_kmh,
           (json_data ->> 'pres')::NUMERIC AS avg_pressure_hpa,
           (json_data ->> 'tsun')::NUMERIC::INTEGER AS sun_minutes
    FROM daily_raw
)
SELECT *
FROM daily_flattened
WHERE date BETWEEN '2017-07-28' AND '2017-09-28'


CREATE TABLE harvey_stg_weather_hourly as
WITH hourly_raw AS (
					SELECT airport_code
							,station_id
							,JSON_ARRAY_ELEMENTS(extracted_data -> 'data') AS json_data
					FROM harvey_weather_hourly_raw		
),
hourly_flattened AS (
					SELECT airport_code
							,station_id
							,(json_data ->> 'time')::timestamp  AS timestamp
							,(json_data ->> 'temp')::NUMERIC AS avg_temp_c
							,(json_data ->> 'dwpt')::NUMERIC AS dew_point_in_c
							,(json_data ->> 'rhum')::NUMERIC AS humidity_in_percent
							,(json_data ->> 'prcp')::NUMERIC AS precipitation_mm
							,(json_data ->> 'snow')::NUMERIC::INTEGER AS max_snow_mm
							,(json_data ->> 'wdir')::NUMERIC::INTEGER AS avg_wind_direction
							,(json_data ->> 'wspd')::NUMERIC AS avg_wind_speed
							,(json_data ->> 'wpgt')::NUMERIC AS avg_peakgust
							,(json_data ->> 'pres')::NUMERIC AS avg_pressure_hpa
							,(json_data ->> 'tsun')::NUMERIC::INTEGER AS sun_minutes
							,(json_data ->> 'coco')::NUMERIC::INTEGER AS weather_condition_code
						FROM hourly_raw
)
SELECT * 
FROM hourly_flattened
WHERE timestamp::DATE BETWEEN '2017-07-28' AND '2017-09-28';

CREATE TABLE harvey_stg_weather_hourly as

WITH hourly_raw AS (
					SELECT airport_code
							,station_id
							,JSON_ARRAY_ELEMENTS(extracted_data -> 'data') AS json_data
					FROM harvey_weather_hourly_raw_data
),
hourly_flattened AS (
					SELECT airport_code
							,station_id
							,(json_data ->> 'time')::timestamp  AS timestamp
							,(json_data ->> 'temp')::NUMERIC AS avg_temp_c
							,(json_data ->> 'dwpt')::NUMERIC AS dew_point_in_c
							,(json_data ->> 'rhum')::NUMERIC AS humidity_in_percent
							,(json_data ->> 'prcp')::NUMERIC AS precipitation_mm
							,(json_data ->> 'snow')::NUMERIC::INTEGER AS max_snow_mm
							,(json_data ->> 'wdir')::NUMERIC::INTEGER AS avg_wind_direction
							,(json_data ->> 'wspd')::NUMERIC AS avg_wind_speed
							,(json_data ->> 'wpgt')::NUMERIC AS avg_peakgust
							,(json_data ->> 'pres')::NUMERIC AS avg_pressure_hpa
							,(json_data ->> 'tsun')::NUMERIC::INTEGER AS sun_minutes
							,(json_data ->> 'coco')::NUMERIC::INTEGER AS weather_condition_code
						FROM hourly_raw
)
SELECT * 
FROM hourly_flattened
WHERE timestamp::DATE BETWEEN '2017-07-28' AND '2017-09-28';