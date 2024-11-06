# 1. 필터 사용 여부에 따른 첫번째 퍼널 전환율
# 공고리스트 페이지 -> 공고페이지: 필터 사용한 유저 vs. 그 외 유저
WITH 
jdlist_view AS(
  SELECT session_id,
         JSON_VALUE(event_property, '$.use_skill_filter') AS filter_yn
  FROM freeo_data.log_data
  WHERE event_name='jdlist_view'
),
jd_view AS(
  SELECT session_id
  FROM freeo_data.log_data
  WHERE event_name='jd_view'
)
SELECT L.filter_yn,
       COUNT(L.session_id) AS first_view_cnt,
       COUNTIF(J.session_id is NOT NULL) AS second_view_cnt,
       ROUND(COUNTIF(J.session_id is NOT NULL)/COUNT(L.session_id), 4) AS conversion
FROM jdlist_view AS L 
LEFT JOIN jd_view AS J 
  ON L.session_id=J.session_id
GROUP BY 1;

# 2. 배포 전후 성과
WITH 
jdlist AS(
  # 공고리스트 페이지 진입 세션 목록
  SELECT DATE(timestamp) AS dt,
        session_id
  FROM freeo_data.project_log
  WHERE event_name="jdlist_view"
),
jd AS(
  # 공고 페이지 진입 세션 목록
  SELECT DATE(timestamp) AS dt,
         session_id
  FROM freeo_data.project_log
  WHERE event_name="jd_view"
)
# 전환율 계산
SELECT L.dt AS date,
       COUNT(L.session_id) AS jdlist_cnt,
       COUNTIF(J.session_id IS NOT NULL) AS jd_cnt,
       ROUND(COUNTIF(J.session_id IS NOT NULL)/COUNT(L.session_id), 4) AS conversion
FROM jdlist AS L 
LEFT JOIN jd AS J 
  ON L.dt=J.dt
    AND L.session_id=J.session_id
GROUP BY 1
ORDER BY 1;

# 3. AB TEST에 따른 성과
WITH 
jdlist AS(
  # 공고리스트 페이지 진입 세션 목록
  SELECT DATE(timestamp) AS dt,
        session_id,
        JSON_VALUE(user_property,'$.experiment') AS experiment
  FROM freeo_data.experiment_log
  WHERE event_name="jdlist_view"
    AND DATE(timestamp)>='2024-02-06' # 배포일 이후만
),
jd AS(
  # 공고 페이지 진입 세션 목록
  SELECT DATE(timestamp) AS dt,
         session_id,
         JSON_VALUE(user_property,'$.experiment') AS experiment
  FROM freeo_data.experiment_log
  WHERE event_name="jd_view"
    AND DATE(timestamp)>='2024-02-06' # 배포일 이후만
)

# experiment별 젼환율 계산
SELECT L.dt AS date,
       # 스킬필터 사용 X
       ROUND(COUNTIF(J.experiment='A' 
             AND J.experiment IS NOT NULL)/COUNTIF(L.experiment='A'),4) AS conversion_A, 
       # 스킬필터 사용
       ROUND(COUNTIF(J.experiment='B' 
             AND J.experiment IS NOT NULL)/COUNTIF(L.experiment='B'),4) AS conversion_B 
FROM jdlist AS L
LEFT JOIN jd AS J
  ON L.dt=J.dt
  AND L.session_id=J.session_id
GROUP BY 1
ORDER BY 1;