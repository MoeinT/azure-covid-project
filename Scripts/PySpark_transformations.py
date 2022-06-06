import os

import pyspark
from azure.storage.blob import BlobClient, BlobServiceClient, ContainerClient
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
    df_hospitals_processed.write.format("csv").save(path_target, mode="overwrite")


def load_images_container(local_path, connection_string, con_name):
    """
    This function will automatically trasnfer csv files from a local directory into a blob storage account.
    Keyword arguments:
    local_path -- The path to the local diectory where the csv files are stored (default ../data/raw)
    connection_string -- The connection string associated with the storage account on Azure
    con_name -- The name of the blob storage container (default "processedmoeinpython")
    """
    df_hospitals_processed = transform_hospitals(extract(local_path))
    df_blob = df_hospitals_processed.write.format("csv")

    try:
        # Connect to the resource group
        blob_service_client = BlobServiceClient.from_connection_string(
            connection_string
        )

        # Connect to a container within that group
        container_client = blob_service_client.get_container_client(con_name)

        if os.path.exists(local_path):

            print("\nUploading the file into Azure Storage Blob\n")

            blob_client = blob_service_client.get_blob_client(
                container=con_name, blob="hospitals_admissions.csv"
            )
            df_hospitals_processed.write.mode("overwrite").option(
                "header", "true"
            ).format("hospitals_admissions.csv").save(container_client)
            # blob_client.upload_blob(df_blob)

            # with open(local_path, "rb") as data:
            #   blob_client.upload_blob(data)

        else:
            print(f"Address '{local_path}' not found!")

    except Exception as ex:
        print(ex)
        # print("Exception:\nThe file already exist in the blob storage container")


if __name__ == "__main__":

    local_path = os.path.join("..", "data", "raw", "hospitals_admissions.csv")
    path_target = os.path.join(
        "..", "data", "processed", "hospitals_admissions_processed.csv"
    )
    conn_string = "DefaultEndpointsProtocol=https;AccountName=covrepsadlmoein;AccountKey=8lB7Lh0HQeHVJVGUhtOTHC1KqUVpb9w2wf4/qwycT6rSGmg7t98loQp8aa6pk6fewGYSpxDAdWbk+AStczvcCQ==;EndpointSuffix=core.windows.net"  # os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    connection_name = "processedmoeinpython"

    load(path_source=local_path, path_target=path_target)

    load_images_container(
        local_path=local_path, connection_string=conn_string, con_name=connection_name
    )
