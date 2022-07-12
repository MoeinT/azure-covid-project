# COMMAND ----------
import os

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# COMMAND ----------


schema_test = StructType(
    [
        StructField("country", StringType(), False),
        StructField("country_code", StringType(), True),
        StructField("year_week", StringType(), True),
        StructField("level", StringType(), True),
        StructField("region", StringType(), True),
        StructField("region_name", StringType(), True),
        StructField("new_cases", IntegerType(), True),
        StructField("tests_done", IntegerType(), True),
        StructField("population", IntegerType(), False),
        StructField("testing_rate", FloatType(), True),
        StructField("positivity_rate", FloatType(), True),
        StructField("testing_data_source", StringType(), True),
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


def extract_tests(path, schema=schema_test):
    return spark.read.schema(schema).csv(path=path, sep="\t", header=True)


def extract_dim_date(path, schema=schema_dim_date):
    return spark.read.schema(schema).csv(path=path, sep=",", header=True)


def extract_loookup(path, schema=schema_lookup):
    return spark.read.schema(schema).csv(path=path, sep=",", header=True)


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


def process_tests(df_tests, path_dim_date, path_country_lookup):
    df_dim_date_processed = process_dim_date(extract_dim_date(path_dim_date))
    df_country_lookup = extract_loookup(path_country_lookup)
    return (
        df_tests.dropna(thresh=2)
        .withColumn(
            "testing_data_source", regexp_replace(col("testing_data_source"), "\n", "")
        )
        .drop("level", "region", "region_name")
        .join(df_dim_date_processed, on="year_week", how="leftouter")
        .withColumnRenamed("country_code", "country_code_2_digit")
        .join(
            df_country_lookup.select("country_code_2_digit", "country_code_3_digit"),
            on="country_code_2_digit",
            how="leftouter",
        )
        .select(
            "country",
            "country_code_2_digit",
            "country_code_3_digit",
            "population",
            "year_week",
            "reported_week_start_date",
            "reported_week_end_date",
            "new_cases",
            "tests_done",
            "testing_rate",
            "positivity_rate",
            "testing_data_source",
        )
    )


# COMMAND ----------

path_dim_date = "/mnt/covrepsadlmoein/lookups/dim_date"
path_country_lookup = "/mnt/covrepsadlmoein/lookups/country_lookup"
path_tests_raw = "/mnt/covrepsadlmoein/rawmoein/ecdc/testing"
df_tests_processed = process_tests(
    extract_tests(path_tests_raw), path_dim_date, path_country_lookup
)

# COMMAND ----------

path_tests_processed = "/mnt/covrepsamoein/processedmoein/ecdc/covidtests"
df_tests_processed.write.format("com.databricks.spark.csv").option(
    "header", "true"
).option("delimiter", ",").mode("overwrite").save(path_tests_processed)
