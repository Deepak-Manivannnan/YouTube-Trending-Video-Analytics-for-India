-- ============================================================
-- DATASET OVERVIEW
-- ============================================================

-- Total number of records
SELECT COUNT(*) AS total_rows
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- Dataset time period
SELECT
  MIN(EXTRACT(YEAR FROM published_at)) AS start_year,
  MAX(EXTRACT(YEAR FROM published_at)) AS end_year
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- Total unique videos, channels, categories, and languages
SELECT
  COUNT(video_title) AS total_videos,
  COUNT(DISTINCT channel_title) AS total_channels,
  COUNT(DISTINCT category_name) AS total_categories,
  COUNT(DISTINCT language) AS total_languages
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- ============================================================
-- CONTENT CATEGORY ANALYSIS
-- ============================================================

-- Top categories by total trending videos

SELECT
  category_name,
  COUNT(*) AS total_trending_videos
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY total_trending_videos DESC;

-- Top categories by total views

SELECT
  category_name,
  SUM(view_count) AS total_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY total_views DESC;

-- Top categories by average views per video

SELECT
  category_name,
  ROUND(AVG(view_count), 2) AS average_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY average_views DESC;

-- Top categories by interaction rate

SELECT
  category_name,
  ROUND(
    SAFE_DIVIDE(
      SUM(likes) + SUM(dislikes) + SUM(comment_count),
      SUM(view_count))
      * 100,
    2) AS interaction_rate
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY interaction_rate DESC;

-- Top categories by comments and ratings disabled percentage

SELECT
  category_name,
  ROUND(AVG(CAST(comments_disabled AS INT64)) * 100, 2)
    AS comments_disabled_percentage,
  ROUND(AVG(CAST(ratings_disabled AS INT64)) * 100, 2)
    AS ratings_disabled_percentage
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY comments_disabled_percentage DESC, ratings_disabled_percentage DESC;

-- ============================================================
-- CHANNEL PERFORMANCE ANALYSIS
-- ============================================================

-- Top channels by total trending videos

SELECT
  channel_title,
  COUNT(*) AS total_trending_videos
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY channel_title
ORDER BY total_trending_videos DESC
LIMIT 10;

-- Top channels by total views

SELECT channel_title, SUM(view_count) AS total_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY channel_title
ORDER BY total_views DESC
LIMIT 10;

-- Top channels by average views

SELECT channel_title, ROUND(AVG(view_count), 2) AS average_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY channel_title
ORDER BY average_views DESC
LIMIT 10;

-- Top channels by interaction rate

SELECT
  channel_title,
  ROUND(
    SAFE_DIVIDE(
      SUM(likes) + SUM(dislikes) + SUM(comment_count), SUM(view_count))
      * 100,
    2) AS interaction_rate
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY channel_title
ORDER BY interaction_rate DESC
LIMIT 10;

-- Channels publishing across the highest number of categories

SELECT channel_title, COUNT(DISTINCT category_name) AS total_categories
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY channel_title
ORDER BY total_categories DESC
LIMIT 10;

-- ============================================================
-- VIDEO PERFORMANCE ANALYSIS
-- ============================================================

-- Top videos by views

SELECT video_title, view_count
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
ORDER BY view_count DESC
LIMIT 10;

-- Videos remaining on Trending for the most days

SELECT video_title, days_trending
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
ORDER BY days_trending DESC
LIMIT 10;

-- Top videos by interaction rate

SELECT
  video_title,
  ROUND(
    SAFE_DIVIDE((likes + dislikes + comment_count), view_count)
      * 100,
    2) AS interaction_rate
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
ORDER BY interaction_rate DESC
LIMIT 10;

-- Percentage of trending videos with comments disabled

SELECT
  ROUND(AVG(CAST(comments_disabled AS INT64)) * 100, 2)
    AS comments_disabled_percentage
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- Percentage of trending videos with ratings disabled

SELECT
  ROUND(AVG(CAST(ratings_disabled AS INT64)) * 100, 2)
    AS ratings_disabled_percentage
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- ============================================================
-- LANGUAGE ANALYSIS
-- ============================================================

-- Top languages by total trending videos

SELECT language, COUNT(*) AS total_trending_videos
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY language
ORDER BY total_trending_videos DESC;

-- Top languages by average views

SELECT language, ROUND(AVG(view_count), 2) AS average_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY language
ORDER BY average_views DESC;

-- Top languages by interaction rate

SELECT
  language,
  ROUND(
    SAFE_DIVIDE(
      SUM(likes) + SUM(dislikes) + SUM(comment_count), SUM(view_count))
      * 100,
    2) AS interaction_rate
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY language
ORDER BY interaction_rate DESC;

-- Highest performing category within each language by views

SELECT
  language,
  category_name,
  SUM(view_count) AS total_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY language, category_name
QUALIFY
  ROW_NUMBER() OVER (PARTITION BY language ORDER BY SUM(view_count) DESC) = 1;

-- Highest performing channel within each language by views

SELECT
  language,
  channel_title,
  SUM(view_count) AS total_views
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY language, channel_title
QUALIFY
  ROW_NUMBER() OVER (PARTITION BY language ORDER BY SUM(view_count) DESC) = 1;

-- ============================================================
-- PUBLISHING & TRENDING PATTERN ANALYSIS
-- ============================================================

-- Trending videos by year

SELECT
  EXTRACT(YEAR FROM first_trending_date) AS trending_year,
  COUNT(*) AS total_trending_videos
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY trending_year
ORDER BY trending_year ASC;

-- Trending videos published by weekday

SELECT
  FORMAT_TIMESTAMP('%A', published_at) AS weekday,
  COUNT(*) AS total_videos
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY weekday
ORDER BY total_videos DESC;

-- Interaction rate by publishing weekday

SELECT
  FORMAT_TIMESTAMP('%A', published_at) AS weekday,
  ROUND(
    SAFE_DIVIDE(
      SUM(likes) + SUM(dislikes) + SUM(comment_count), SUM(view_count))
      * 100,
    2) AS interaction_rate
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY weekday
ORDER BY interaction_rate DESC;



-- Average time taken to reach the Trending page

SELECT
  ROUND(AVG(days_to_trend), 2) AS average_days_to_trend
FROM
  `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`;

-- Average time to trend by content category

SELECT
  category_name,
  ROUND(AVG(days_to_trend), 2) AS average_days_to_trend
FROM `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
GROUP BY category_name
ORDER BY average_days_to_trend ASC;

-- Best performing publishing weekday within each category

SELECT category_name, weekday, interaction_rate
FROM
  (
    SELECT
      category_name,
      FORMAT_TIMESTAMP('%A', published_at) AS weekday,
      ROUND(
        SAFE_DIVIDE(
          SUM(likes) + SUM(dislikes) + SUM(comment_count), SUM(view_count))
          * 100,
        2) AS interaction_rate,
      RANK()
        OVER (
          PARTITION BY category_name
          ORDER BY
            SAFE_DIVIDE(
              SUM(likes) + SUM(dislikes) + SUM(comment_count),
              SUM(view_count)) DESC
        ) AS rank
    FROM
      `india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data`
    GROUP BY category_name, weekday
  )
WHERE rank = 1;
