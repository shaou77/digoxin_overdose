DROP TABLE IF EXISTS first_day_ventilation; CREATE TABLE first_day_ventilation AS
WITH temp AS
(SELECT ve.* FROM mimiciv_icu.icustays ie
LEFT JOIN mimiciv_derived.ventilation ve
    ON ie.stay_id = ve.stay_id
        AND ve.starttime >= ie.intime - INTERVAL '6' HOUR
        AND ve.starttime <= ie.intime + INTERVAL '1' DAY
WHERE ve.ventilation_status NOT IN ('SupplementalOxygen','None','HFNC')),
temp2 as
(SELECT stay_id, count(ventilation_status) as flag FROM temp
GROUP BY stay_id)
SELECT stay_id, 
CASE 	WHEN flag>0 THEN 1 ELSE 0 END  as ventilation
	FROM temp2 ORDER BY stay_id