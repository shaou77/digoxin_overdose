DROP MATERIALIZED VIEW IF EXISTS digoxin_patients;
CREATE MATERIALIZED VIEW digoxin_patients
AS
SELECT subject_id,hadm_id,starttime,stoptime, dose_val_rx, route
FROM "mimiciv_hosp"."prescriptions"
where drug ilike 'Digoxin'