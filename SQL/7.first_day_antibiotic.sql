-- 创建first_day_antibiotic表，记录ICU入住后24小时内是否使用了抗生素
CREATE TABLE first_day_antibiotic AS
WITH icu_stays AS (
    -- 选择所有ICU住院记录
    SELECT 
        stay_id,
        subject_id,
        hadm_id,
        icu_intime,
        -- 计算ICU入住后24小时的时间点
        icu_intime + INTERVAL '24 hours' AS first_day_end
    FROM 
        mimiciv_derived.icustay_detail
),

antibiotic_usage AS (
    -- 确定每个stay_id在ICU入住后24小时内是否使用抗生素
    SELECT DISTINCT
        i.stay_id,
        1 AS has_antibiotic  -- 如果有任何匹配记录，表示使用了抗生素
    FROM 
        icu_stays i
    JOIN 
        antibiotic a
    ON 
        -- 连接条件：相同的病人ID和住院ID
        (i.subject_id = a.subject_id)
        AND 
        -- 有三种情况需要考虑:
        (
            -- 1. 抗生素stay_id与ICU stay_id直接匹配
            (a.stay_id = i.stay_id AND a.stay_id IS NOT NULL)
            OR
            -- 2. 抗生素stay_id为空，但hadm_id匹配
            (a.stay_id IS NULL AND a.hadm_id = i.hadm_id)
            OR
            -- 3. 抗生素stay_id和hadm_id都为空，只匹配subject_id
            (a.stay_id IS NULL AND a.hadm_id IS NULL)
        )
    WHERE
        -- 确保抗生素使用时间与ICU首日有重叠
        (
            -- 抗生素开始时间在ICU首日内
            (a.starttime >= i.icu_intime AND a.starttime < i.first_day_end)
            OR
            -- 抗生素结束时间在ICU首日内
            (a.stoptime >= i.icu_intime AND a.stoptime < i.first_day_end)
            OR
            -- 抗生素使用时间段完全包含ICU首日
            (a.starttime <= i.icu_intime AND a.stoptime >= i.first_day_end)
        )
)

-- 最终查询：为所有ICU住院记录创建指示器
SELECT 
    i.stay_id,
    COALESCE(au.has_antibiotic, 0) AS has_antibiotic
FROM 
    icu_stays i
LEFT JOIN 
    antibiotic_usage au ON i.stay_id = au.stay_id
ORDER BY 
    i.stay_id;