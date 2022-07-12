# COMMAND ----------
import os

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# COMMAND ----------

schema_casesdeaths = StructType(
    [
        StructField("country", StringType(), False),
        StructField("country_code", StringType(), True),
        StructField("continent", StringType(), True),
        StructField("population", IntegerType(), True),
        StructField("indicator", StringType(), True),
        StructField("weekly_count", IntegerType(), True),
        StructField("year_week", StringType(), True),
        StructField("rate_14_day", FloatType(), True),
        StructField("cumulative_count", IntegerType(), True),
        StructField("source", StringType(), True),
        StructField("note", StringType(), True),
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


def extract_cases_deaths(path, schema=schema_casesdeaths):
    return spark.read.schema(schema).csv(path=path, sep="\t", header=True)


def extract_dim_date(path, schema=schema_dim_date):
    return spark.read.schema(schema).csv(path=path, sep=",", header=True)


def process_dim_date(df):
    return (
        df.withColumn(
            "year_week", concat_ws("-W", col("year"), lpad(col("week_of_year"), 2, "0"))
        )
        .withColumnRenamed("year_week", "reported_year_week")
        .groupby(col("reported_year_week"))
        .agg(
            min("date").alias("reported_week_start_date"),
            max("date").alias("reported_week_end_date"),
        )
    )


def process_cases_death(df, path_lookup, path_dim_date):

    df_country_lookup = extract_lookup(path=path_lookup)
    df_dim_date = process_dim_date(extract_dim_date(path=path_dim_date))

    return (
        df.drop("continent", "rate_14_day", "cumulative_count", "note")
        .withColumnRenamed("year_week", "reported_year_week")
        .withColumnRenamed("country_code", "country_code_3_digit")
        .withColumn(
            "reported_year_week", regexp_replace(col("reported_year_week"), "-", "-W")
        )
        .groupby(
            "country",
            "country_code_3_digit",
            "population",
            "reported_year_week",
            "source",
        )
        .pivot("indicator")
        .agg(sum(col("weekly_count")))
        .withColumnRenamed("cases", "cases_count")
        .withColumnRenamed("deaths", "deaths_count")
        .join(df_dim_date, on="reported_year_week", how="leftouter")
        .join(
            df_country_lookup.drop("population", "country_code_3_digit"),
            on="country",
            how="leftouter",
        )
        .select(
            "country",
            "country_code_2_digit",
            "country_code_3_digit",
            "population",
            "reported_year_week",
            "reported_week_start_date",
            "reported_week_end_date",
            "cases_count",
            "deaths_count",
            "source",
        )
        .orderBy(col("country").asc(), col("reported_week_start_date").asc())
        .withColumn("source", regexp_replace(col("source"),"," , ""))
        .dropna(thresh = 2)
    )


# COMMAND ----------

path_dim_date = "/mnt/covrepsadlmoein/lookups/dim_date"
path_country_lookup = "/mnt/covrepsadlmoein/lookups/country_lookup"
path_casesdeaths = "/mnt/covrepsadlmoein/rawmoein/ecdc/cases_deaths"
df_cases_deaths_processed = process_cases_death(
    extract_cases_deaths(path_casesdeaths), path_country_lookup, path_dim_date
)

# COMMAND ----------
path_casesdeaths_processed = "/mnt/covrepsamoein/processedmoein/ecdc/casesdeaths"
df_cases_deaths_processed.write.format("com.databricks.spark.csv").option(
    "header", "true"
).option("delimiter", ",").mode("overwrite").save(path_casesdeaths_processed)
