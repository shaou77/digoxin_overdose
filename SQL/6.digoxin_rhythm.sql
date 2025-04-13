DROP MATERIALIZED VIEW IF EXISTS mimiciv_derived.digoxin_rhythm;

CREATE MATERIALIZED VIEW mimiciv_derived.digoxin_rhythm AS
WITH cohort AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        icu_intime,
        LEAST(dischtime, icu_intime + INTERVAL '24 hours') AS icu_24h_end
    FROM mimiciv_derived.digoxin_cohort
),
first_rhythm AS (
    SELECT
        c.stay_id,
        r.charttime,
        r.heart_rhythm,
        ROW_NUMBER() OVER (PARTITION BY c.stay_id ORDER BY r.charttime) AS rn
    FROM cohort c
    JOIN mimiciv_derived.rhythm r
      ON r.subject_id = c.subject_id
     AND r.charttime >= c.icu_intime
     AND r.charttime <= c.icu_24h_end
    WHERE r.heart_rhythm IS NOT NULL
      AND r.heart_rhythm <> ''
)
SELECT
    c.subject_id,
    c.hadm_id,
    c.stay_id,
    c.icu_intime,
    fr.charttime  AS rhythm_time,
    fr.heart_rhythm
FROM cohort c
LEFT JOIN first_rhythm fr
       ON fr.stay_id = c.stay_id
      AND fr.rn      = 1;

CREATE INDEX ON mimiciv_derived.digoxin_rhythm (stay_id);
CREATE INDEX ON mimiciv_derived.digoxin_rhythm (subject_id);
