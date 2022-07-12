# COMMAND ----------
import os

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# COMMAND ----------

schema_lookup = StructType(
    [
        StructField("country", StringType(), True),
        StructField("country_code_2_digit", StringType(), True),
        StructField("country_code_3_digit", StringType(), True),
        StructField("continent", StringType(), True),
        StructField("population", IntegerType(), True),
        StructField("id", IntegerType(), True),
    ]
)

schema_population = StructType(
    [
        StructField("indic_de,geo\\time", StringType(), True),
        StructField("2008 ", FloatType(), True),
        StructField("2009 ", FloatType(), True),
        StructField("2010 ", FloatType(), True),
        StructField("2011 ", FloatType(), True),
        StructField("2012 ", FloatType(), True),
        StructField("2013 ", FloatType(), True),
        StructField("2014 ", FloatType(), True),
        StructField("2015 ", FloatType(), True),
        StructField("2016 ", FloatType(), True),
        StructField("2017 ", FloatType(), True),
        StructField("2018 ", FloatType(), True),
        StructField("2019 ", FloatType(), True),
    ]
)

# COMMAND ----------


def extract_population(path, schema=schema_population):
    return spark.read.schema(schema).csv(path, sep="\t", header=True)


def extract_lookup(path, schema=schema_lookup):
    return spark.read.schema(schema).csv(path, sep=",", header=True)


def population_processed(df, path_lookup):

    df_lookup_country = extract_lookup(path_lookup)

    return (
        df.withColumn(
            "indic_de,geo\\time",
            regexp_replace(col("indic_de,geo\\time"), "PC_Y", "age_group_"),
        )
        .withColumn("split_col", split(col("indic_de,geo\\time"), ","))
        .withColumn("age_group", col("split_col").getItem(0))
        .withColumn("country_code_2_digit", col("split_col").getItem(1))
        .drop("split_col")
        .drop("indic_de,geo\\time")
        .select("age_group", "country_code_2_digit", "2019 ")
        .withColumnRenamed("2019 ", "2019")
        .groupBy("country_code_2_digit")
        .pivot("age_group")
        .agg(round(sum("2019"), 2))
        .dropna(how="any")
        .join(df_lookup_country, on="country_code_2_digit", how="Leftouter")
        .select(
            "country",
            "country_code_2_digit",
            "country_code_3_digit",
            "population",
            "age_group_0_14",
            "age_group_15_24",
            "age_group_25_49",
            "age_group_50_64",
            "age_group_65_79",
            "age_group_80_MAX",
        )
    )


# COMMAND ----------
path_pop = "/mnt/covrepsadlmoein/rawmoein/population"
path_lookup = "/mnt/covrepsadlmoein/lookups/country_lookup"
df_population_processed = population_processed(
    extract_population(path_pop), path_lookup
)
# COMMAND ----------
path_tests_processed = "/mnt/covrepsamoein/processedmoein/population"
df_population_processed.write.format("com.databricks.spark.csv").option(
    "header", "true"
).option("delimiter", ",").mode("overwrite").save(path_tests_processed)
