DROP MATERIALIZED VIEW IF EXISTS digoxin_concentrate;
CREATE MATERIALIZED VIEW digoxin_concentrate
AS
SELECT 
  subject_id,hadm_id,charttime,valuenum,
  CASE 
  WHEN valuenum > 2 THEN 1 
  ELSE 0 
END AS overdose
FROM labevents
where itemid = 50917
