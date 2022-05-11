resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covrepdfmoein"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

#Link adf to the source (azure blob storage)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf-link-source" {
  name              = "ls_ablobs_covrepmoein"
  data_factory_id   = azurerm_data_factory.covid-reporting-df.id
  connection_string = azurerm_storage_account.covid-reporting-sa.primary_connection_string
}

#Lind adf to the target (dlg2)
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf-link-target" {
  name                = "ls_adls_covrepmoein"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  url                 = "https://${azurerm_storage_account.covid-reporting-sa-dl.name}.dfs.core.windows.net"
  storage_account_key = azurerm_storage_account.covid-reporting-sa-dl.primary_access_key
}

#Create a dataset for the source 
resource "azurerm_data_factory_dataset_delimited_text" "ds-source" {
  name                = "ds_population_moein_gz"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf-link-source.name

  azure_blob_storage_location {
    container = azurerm_storage_container.blob-container-population.name
    filename  = "population_by_age.tsv.gz"
  }
  first_row_as_header = true
  compression_codec   = "gzip"
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a dataset for the target
resource "azurerm_data_factory_dataset_delimited_text" "ds-target" {
  name                = "ds_population_moein_tsv"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    #path        = "population"
    filename = "population_by_age.tsv"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a pipeline
resource "azurerm_data_factory_pipeline" "pl_ingest_population" {
  name            = "pl_ingest_pop_moein"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1

  activities_json = <<JSON
[
    {
    "name": "pl_ingest_pop_moein",
    "properties": {
        "activities": [
            {
                "name": "Copy Population Data",
                "type": "Copy",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.00:05:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "DelimitedTextSource",
                        "storeSettings": {
                            "type": "AzureBlobStorageReadSettings",
                            "recursive": true,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "DelimitedTextReadSettings"
                        }
                    },
                    "sink": {
                        "type": "DelimitedTextSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "DelimitedTextWriteSettings",
                            "quoteAllText": true,
                            "fileExtension": ".txt"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "ds_population_moein_gz",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_population_moein_tsv",
                        "type": "DatasetReference"
                    }
                ]
            }
        ],
        "concurrency": 1,
        "annotations": [],
        "lastPublishTime": "2022-05-11T18:36:36Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}
]
  JSON

}