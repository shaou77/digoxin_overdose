DROP TABLE IF EXISTS first_day_vasoactive; CREATE TABLE first_day_vasoactive AS
with temp AS
(SELECT va.* 
FROM mimiciv_icu.icustays ie
LEFT JOIN mimiciv_derived.vasoactive_agent va
    ON ie.stay_id = va.stay_id
        AND va.starttime >= ie.intime - INTERVAL '6' HOUR
        AND va.starttime <= ie.intime + INTERVAL '1' DAY),
temp2 AS
(SELECT stay_id, (count(dopamine) + count(epinephrine) + count(norepinephrine) + 
    count(phenylephrine) + count(vasopressin) + count(dobutamine) +
    count(milrinone)) as flag FROM temp
		GROUP BY stay_id)
SELECT stay_id, 
CASE 	WHEN flag>0 THEN 1 ELSE 0 END  as vasoactive
	FROM temp2 ORDER BY stay_id