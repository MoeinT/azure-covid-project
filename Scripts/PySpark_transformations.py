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


def load(path_source, path_target):
    df_hospitals_processed = transform_hospitals(extract(path_source))
    print(f"Writing to: {path_target}..")
    print(df_hospitals_processed.show(2))
    df_hospitals_processed.write.format("csv").save(path_target, mode="overwrite")


if __name__ == "__main__":
    load(
        path_source=os.path.join("..", "data", "raw", "hospitals_admissions.csv"),
        path_target=os.path.join(
            "data", "processed", "hospitals_admissions_processed.csv"
        ),
    )
