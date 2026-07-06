# Import Required Libraries
from pyspark.sql import SparkSession
from pyspark.sql.types import StringType
from pyspark.sql.functions import col, to_timestamp, trim, udf, explode
import pyspark.sql.functions as F

# Create Spark Session
spark = SparkSession.builder.appName("Youtube Trending ETL").getOrCreate()

# Load Source Datasets
videos_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .option("multiLine", True)
    .option("escape", '"')
    .csv("gs://india_youtube_trending_data_lake/raw/In_youtube_trending_data.csv")
)

categories_df = spark.read.option("multiline", True).json("gs://india_youtube_trending_data_lake/raw/IN_category_id.json")

## Clean YouTube Trending Dataset
# Remove columns that are not required for analysis
videos_df = videos_df.drop("channelId","thumbnail_link","description")

# Convert date columns to timestamp data type
videos_df = videos_df.withColumn("publishedAt", to_timestamp(col("publishedAt")))
videos_df = videos_df.withColumn("trending_date", to_timestamp(col("trending_date")))

# Remove rows containing missing values
videos_df = videos_df.dropna()

# Remove duplicate rows
videos_df = videos_df.dropDuplicates()

# Remove trailing/leading spaces
videos_df = (
    videos_df
    .withColumn("title", trim(col("title")))
    .withColumn("channelTitle", trim(col("channelTitle")))
)

# Standardize column names for consistency
videos_df = (
    videos_df
    .withColumnRenamed("title","video_title")
    .withColumnRenamed("publishedAt", "published_at")
    .withColumnRenamed("channelTitle", "channel_title")
    .withColumnRenamed("categoryId", "category_id")
)

# Create a new column
language_keywords = {
    "English" : ["english"],
    "Hindi": ["hindi"],
    "Tamil": ["tamil"],
    "Telugu": ["telugu"],
    "Malayalam": ["malayalam"],
    "Kannada": ["kannada"],
    "Punjabi": ["punjabi"],
    "Bengali": ["bengali", "bangla"],
    "Marathi": ["marathi"],
    "Gujarati": ["gujarati"],
    "Odia": ["odia", "oriya"]
}

def detect_language(title, tags):
    title = str(title).lower()
    tags = str(tags).lower()

    for language, keywords in language_keywords.items():
        if any(keyword in title for keyword in keywords):
            return language
        elif any(keyword in tags for keyword in keywords):
            return language

    return "Unknown"

# Register the custom Python function as a Spark UDF
language_udf = udf(detect_language, StringType())

# Create the language column using the custom UDF
videos_df = videos_df.withColumn(
    "language",
    language_udf(col("video_title"), col("tags"))
)

# Remove the temporary tags column after language extraction
videos_df = videos_df.drop("tags")

# Remove rows that have 0 view counts
videos_df = videos_df.filter(col("view_count")!=0)

# Consolidate multiple trending rows into one row per unique video
videos_df = videos_df.groupBy("video_id").agg(
    F.last("video_title").alias("video_title"),
    F.first("published_at").alias("published_at"),
    F.first("channel_title").alias("channel_title"),
    F.first("language").alias("language"),
    F.first("category_id").alias("category_id"),
    F.min("trending_date").alias("first_trending_date"),
    F.max("trending_date").alias("last_trending_date"),
    F.max("view_count").alias("view_count"),
    F.max("likes").alias("likes"),
    F.max("dislikes").alias("dislikes"),
    F.max("comment_count").alias("comment_count"),
    F.first("comments_disabled").alias("comments_disabled"),
    F.first("ratings_disabled").alias("ratings_disabled")
)

# Derive days_to_trend and days_trending columns
videos_df = videos_df.withColumn(
    "days_to_trend",
    F.datediff(
        F.to_date(col("first_trending_date")),
        F.to_date(col("published_at"))
    )
)

videos_df = videos_df.withColumn(
    "days_trending",
    F.datediff(col("last_trending_date"), col("first_trending_date")) + 1
)

## Clean Category Lookup Dataset
# Flatten the nested JSON structure into a tabular format
categories_df = categories_df.select(
    explode("items").alias("item")
)

categories_df = categories_df.select(
    "item.*"
)

categories_df = categories_df.select(
    "id",
    "kind",
    "snippet.*"
)

# Remove unnecessary lookup columns
categories_df = categories_df.drop("kind", "assignable","channelId")

# Rename columns to maintain a consistent naming convention
categories_df = (
    categories_df
    .withColumnRenamed("id", "category_id")
    .withColumnRenamed("title", "category_name")
)

# Convert category_id to integer for joining
categories_df = categories_df.withColumn("category_id",col("category_id").cast("int"))

# Merge Datasets
merged_df = videos_df.join(categories_df, on="category_id", how="left")

# Replace missing category names caused by unmapped category IDs
merged_df = merged_df.fillna({"category_name":"Unknown Category"})

# Remove category_id as the final dataset uses category_name
merged_df = merged_df.drop("category_id")

# Reorder columns 
merged_df = merged_df.select(
    "video_id",
    "video_title",
    "channel_title",
    "category_name",
    "language",
    "published_at",
    "first_trending_date",
    "last_trending_date",
    "days_to_trend",
    "days_trending",
    "view_count",
    "likes",
    "dislikes",
    "comment_count",
    "comments_disabled",
    "ratings_disabled"
)

# Export Cleaned Dataset
merged_df.write.format("bigquery").option("table", "hidden-will-500909-m5.india_youtube_trending_data_analytics.cleaned_india_youtube_trending_data").option("temporaryGcsBucket", "india_youtube_trending_data_lake").mode("overwrite").save()

spark.stop()