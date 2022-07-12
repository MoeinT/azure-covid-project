# COMMAND ----------
import os

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# COMMAND ----------

schema_hospitals = StructType(
    [
        StructField("country", StringType(), False),
        StructField("indicator", StringType(), True),
        StructField("date", DateType(), True),
        StructField("year_week", StringType(), True),
        StructField("value", FloatType(), True),
        StructField("source", StringType(), True),
        StructField("url", StringType(), True),
    ]
)

schema_dim_date = StructType(
    [
        StructField("date_key", IntegerType(), True),
        StructField("date", DateType(), True),
        StructField("year", IntegerType(), True),
        StructField("month", IntegerType(), True),
        StructField("day", IntegerType(), True),
        StructField("day_name", StringType(), True),
        StructField("day_of_year", IntegerType(), True),
        StructField("week_of_month", IntegerType(), True),
        StructField("week_of_year", IntegerType(), True),
        StructField("month_name", StringType(), True),
        StructField("year_month", StringType(), True),
        StructField("year_week", StringType(), True),
    ]
)

schema_lookup = StructType(
    [
        StructField("country", StringType(), True),
        StructField("country_code_2_digit", StringType(), True),
        StructField("country_code_3_digit", StringType(), True),
        StructField("continent", StringType(), True),
        StructField("population", StringType(), True),
        StructField("id", IntegerType(), True),
    ]
)

# COMMAND ----------


def extract_lookup(path, schema=schema_lookup):
    return (
        spark.read.schema(schema)
        .csv(path=path, sep=",", header=True)
        .drop("continent", "id")
    )


def extract_dim_date(path, schema=schema_dim_date):
    return spark.read.schema(schema).csv(path=path, sep=",", header=True)


def extract_hospital_admissions(path, schema=schema_hospitals):
    return spark.read.schema(schema).csv(path=path, sep="\t", header=True)


def process_dim_date(df):
    return (
        df.withColumn(
            "year_week", concat_ws("-W", col("year"), lpad(col("week_of_year"), 2, "0"))
        )
        .groupby(col("year_week"))
        .agg(
            min("date").alias("reported_week_start_date"),
            max("date").alias("reported_week_end_date"),
        )
    )


def process_daily_file(df, path_lookup):

    df_country_lookup = extract_lookup(path_lookup)
    # df_dim_date = process_dim_date(extract_dim_date(path=path_dim_date))

    return (
        df.dropna(thresh = 2).filter(col("indicator").contains("Daily"))
        .withColumnRenamed("date", "reported_date")
        .drop("url")
        .groupBy("country", "reported_date", "source")
        .pivot("indicator")
        .agg(sum("value"))
        .join(df_country_lookup, on="country", how="leftouter")
        .withColumnRenamed("Daily ICU occupancy", "icu_occupancy_count")
        .withColumnRenamed("Daily hospital occupancy", "hospital_occupancy_count")
        .select(
            "country",
            "country_code_2_digit",
            "country_code_3_digit",
            "population",
            "reported_date",
            "hospital_occupancy_count",
            "icu_occupancy_count",
            "source",
        )
        .orderBy(col("country").asc(), col("reported_date").asc())
        .withColumn("source", regexp_replace(col("source"),"," , ""))
    )


def process_weekly_file(df, path_lookup, path_dim_date):

    df_country_lookup = extract_lookup(path_lookup)
    df_dim_date = process_dim_date(extract_dim_date(path=path_dim_date))

    return (
        df.dropna(thresh = 2).filter(col("indicator").contains("Weekly"))
        .drop("url")
        .groupBy("country", "year_week", "year_week", "source")
        .pivot("indicator")
        .agg(round(sum("value"), 2))
        .withColumnRenamed(
            "Weekly new ICU admissions per 100k", "new_icu_occupancy_count"
        )
        .withColumnRenamed(
            "Weekly new hospital admissions per 100k", "new_hospital_occupancy_count"
        )
        .join(df_country_lookup, on="country", how="leftouter")
        .join(df_dim_date, on="year_week", how="leftouter")
        .withColumnRenamed("year_week", "reported_year_week")
        .select(
            "country",
            "country_code_2_digit",
            "country_code_3_digit",
            "population",
            "reported_year_week",
            "reported_week_start_date",
            "reported_week_end_date",
            "new_hospital_occupancy_count",
            "new_icu_occupancy_count",
            "source"
        ).orderBy(col("country").asc(), col("reported_week_start_date").asc())
         .withColumn("source", regexp_replace(col("source"),"," , ""))
    )


# COMMAND ----------
hospitals_path = "/mnt/covrepsadlmoein/rawmoein/ecdc/hospital_admissions"
path_country_lookup = "/mnt/covrepsadlmoein/lookups/country_lookup"
df_hospitals_daily = process_daily_file(
    extract_hospital_admissions(path=hospitals_path), path_lookup=path_country_lookup
)

# COMMAND ----------
path_dim_date = "/mnt/covrepsadlmoein/lookups/dim_date"
df_hospitals_weekly = process_weekly_file(
    extract_hospital_admissions(hospitals_path),
    path_lookup=path_country_lookup,
    path_dim_date=path_dim_date,
)

# COMMAND ----------
path_hospitals_daily_processed = (
    "/mnt/covrepsamoein/processedmoein/ecdc/hospital_admissions_daily"
)
df_hospitals_daily.write.format("com.databricks.spark.csv").option(
    "header", "true"
).option("delimiter", ",").mode("overwrite").save(path_hospitals_daily_processed)

# COMMAND ----------
path_hospitals_weekly_processed = (
    "/mnt/covrepsamoein/processedmoein/ecdc/hospital_admissions_weekly"
)
df_hospitals_weekly.write.format("com.databricks.spark.csv").option("header", "true").option(
    "delimiter", ","
).mode("overwrite").save(path_hospitals_weekly_processed)
