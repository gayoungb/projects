# 1. 실제 지원 수 현황
# 지원이 실제 감소하는지 주 단위로  확인
SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
       COUNT(session_id) AS apply_cnt
FROM freeo_data.log_data
WHERE event_name='apply'
GROUP BY week
ORDER BY week;


# 2. 퍼널 문제 여부
# 유저 퍼널에 문제가 있는지 확인
WITH 
first_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data 
  WHERE event_name != 'jd_view'
    AND event_name LIKE '%_view'
), 
jd_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data
  WHERE event_name='jd_view'
),
apply_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data
  WHERE event_name='apply'
)

SELECT F.week AS week,
       # 첫번쨰 퍼널(공고리스트/검색/북마크 페이지 -> 공고 페이지)
       ROUND(COUNTIF(J.session_id IS NOT NULL)/COUNT(F.session_id),4) AS first_funnel,
       # 두번째 퍼널(공고 페이지 -> 지원)
       ROUND(COUNTIF(A.session_id IS NOT NULL)/COUNT(J.session_id),4) AS second_funnel
FROM first_view AS F 
LEFT JOIN jd_view AS J 
  ON F.week=J.week
    AND F.session_id=J.session_id
LEFT JOIN apply_view AS A
  ON J.week=A.week
    AND J.session_id=A.session_id
GROUP BY week
ORDER BY week;


# 3. 첫 페이지별 전환율
WITH 
jdlist_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data 
  WHERE event_name='jdlist_view'
), 
search_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data 
  WHERE event_name='search_view'
), 
bookmark_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data 
  WHERE event_name='bookmark_view'
), 
jd_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data
  WHERE event_name='jd_view'
),
apply_view AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         session_id
  FROM freeo_data.log_data
  WHERE event_name='apply'
)

SELECT F.week,
       ROUND(COUNTIF(J.session_id IS NOT NULL)/COUNT(F.session_id),4) AS first_funnel_bookmark,
       ROUND(COUNTIF(A.session_id IS NOT NULL)/COUNT(J.session_id),4) AS second_funnel
--FROM jdlist_view AS F # 공고리스트페이지 -> 공고 페이지 -> 지원
--FROM search_view AS F # 검색 페이지 -> 공고 페이지 -> 지원
FROM bookmark_view AS F # 북마크 페이지 -> 공고 페이지 -> 지원 
LEFT JOIN jd_view AS J 
  ON F.week=J.week
    AND F.session_id=J.session_id
LEFT JOIN apply_view AS A
  ON J.week=A.week
    AND J.session_id=A.session_id
GROUP BY 1
ORDER BY 1;


# 4. 첫 페이지별 유입
# 각각의 첫페이지에 따른 유입량, 유입률 확인
WITH view_cnt AS(
  SELECT DATE(DATE_TRUNC(timestamp, week)) AS week,
         event_name,
         COUNT(session_id) AS session_cnt
  FROM freeo_data.log_data 
  WHERE event_name != 'jd_view'
    AND event_name LIKE '%_view'
  GROUP BY week, event_name)
SELECT *,
       SUM(session_cnt) OVER(PARTITION BY week) AS week_total,
       ROUND(safe_divide(session_cnt, SUM(session_cnt) OVER(PARTITION BY week)), 3) AS session_rate
FROM view_cnt
ORDER BY week, event_name;