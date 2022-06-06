import os

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder.appName("azure-covid-project").getOrCreate()


def extract(path):
    return spark.read.csv(path, header=True, inferSchema=True)


def transform_hospitals(df):
    return (
        df.withColumn("year", split("year_week", "-").getItem(0).cast(IntegerType()))
        .withColumn(
            "week",
            substring(split("year_week", "-").getItem(1), 2, 3).cast(IntegerType()),
        )
        .where(~col("indicator").contains("Weekly"))
        .groupBy("country", "date", "year", "week", "source")
        .pivot("indicator")
        .agg(sum("value"))
    )


def get_date(path_source):

    return transform_hospitals(extract(path_source))


if __name__ == "__main__":
    df_hospitals_processed = get_date(
        os.path.join("..", "data", "raw", "hospitals_admissions.csv")
    )
    print("Ran successfully!")
