# Create a pipeline passing a list of the services you're using in your pipeline
resource "azurerm_data_factory_pipeline" "pl_ingest_population" {
  name            = "pl_ingest_pop_moein"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1

  activities_json = <<JSON
  [
        {
                "name": "Check if file exists",
                "type": "Validation",
                "dependsOn": [],
                "userProperties": [],
                "typeProperties": {
                    "dataset": {
                        "referenceName": "${azurerm_data_factory_dataset_delimited_text.ds-source.name}",
                        "type": "DatasetReference"
                    },
                    "timeout": "1.00:00:00",
                    "sleep": 10,
                    "minimumSize": 1024
                }
            },
            {
                "name": "Get File Metadata",
                "type": "GetMetadata",
                "dependsOn": [
                    {
                        "activity": "Check if file exists",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "dataset": {
                        "referenceName": "${azurerm_data_factory_dataset_delimited_text.ds-source.name}",
                        "type": "DatasetReference"
                    },
                    "fieldList": [
                        "columnCount",
                        "size",
                        "exists"
                    ],
                    "storeSettings": {
                        "type": "AzureBlobStorageReadSettings",
                        "enablePartitionDiscovery": false
                    },
                    "formatSettings": {
                        "type": "DelimitedTextReadSettings"
                    }
                }
            },
            {
                "name": "If Column Count Matches",
                "type": "IfCondition",
                "dependsOn": [
                    {
                        "activity": "Get File Metadata",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "expression": {
                        "value": "@equals(activity('Get File Metadata').output.columnCount, 13)",
                        "type": "Expression"
                    },
                    "ifFalseActivities": [
                        {
                            "name": "Send Email",
                            "type": "WebActivity",
                            "dependsOn": [],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "url": "moin.torabi@gmail.com",
                                "method": "POST",
                                "body": "The pipeline is not working! "
                            }
                        }
                    ],
                    "ifTrueActivities": [
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
                                    "referenceName": "${azurerm_data_factory_dataset_delimited_text.ds-source.name}",
                                    "type": "DatasetReference"
                                }
                            ],
                            "outputs": [
                                {
                                    "referenceName": "${azurerm_data_factory_dataset_delimited_text.ds-target.name}",
                                    "type": "DatasetReference"
                                }
                            ]
                        }
                    ]
                }
            }
  ]
    JSON

}