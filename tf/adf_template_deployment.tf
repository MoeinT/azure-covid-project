#Provision as Azure Data Factory with all its components using an ARM Template
resource "azurerm_data_factory" "covid-reporting-df_template" {
  name                = "covrepdf${local.my_name}1"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

resource "azurerm_resource_group_template_deployment" "adf-template-deployment" {
  name                = "adf_template_${local.my_name}"
  depends_on          = [azurerm_data_factory.covid-reporting-df_template]
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  deployment_mode     = "Incremental"

  template_content = <<JSON
{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "factoryName": {
            "type": "string",
            "metadata": "Data Factory name",
            "defaultValue": "covrepdfmoein1"
        },
        "adf_trigger_blobevent_moein_properties_typeProperties_scope": {
            "type": "string",
            "defaultValue": "/subscriptions/1b7f4ea1-c952-4797-ab87-31c4b9078163/resourceGroups/covreprgmoein/providers/Microsoft.Storage/storageAccounts/covrepsamoein"
        },
        "ls_adls_covrepmoein_properties_typeProperties_url": {
            "type": "string",
            "defaultValue": "https://covrepsadlmoein.dfs.core.windows.net"
        },
        "ls_http_ecdc_moein_properties_typeProperties_url": {
            "type": "string",
            "defaultValue": "@linkedService().sourceBaseURL"
        }
    },
    "variables": {
        "factoryId": "[concat('Microsoft.DataFactory/factories/', parameters('factoryName'))]",
        "ls_ablobs_covrepmoein_connectionString":  "${azurerm_storage_account.covid-reporting-sa.primary_connection_string}",
        "ls_adls_covrepmoein_accountKey": "${azurerm_storage_account.covid-reporting-sa-dl.primary_access_key}"
    },
    "resources": [
        {
            "name": "[concat(parameters('factoryName'), '/ds_population_moein_gz')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_ablobs_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobStorageLocation",
                        "fileName": "population_by_age.tsv.gz",
                        "container": "populationmoeinsource"
                    },
                    "columnDelimiter": "\t",
                    "rowDelimiter": "\n",
                    "compressionCodec": "gzip",
                    "compressionLevel": "Optimal",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_ablobs_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_population_moein_tsv')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": "population_by_age.tsv",
                        "folderPath": "population",
                        "fileSystem": "rawmoein"
                    },
                    "columnDelimiter": "\t",
                    "rowDelimiter": "\n",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_ecdc_raw_csv_http_dlmoein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "parameters": {
                    "fileName": {
                        "type": "String"
                    }
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": {
                            "value": "@dataset().fileName",
                            "type": "Expression"
                        },
                        "folderPath": "ecdc",
                        "fileSystem": "rawmoein"
                    },
                    "columnDelimiter": "\t",
                    "rowDelimiter": "\n",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_ecdc_filelist_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_ablobs_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "Json",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobStorageLocation",
                        "fileName": "ecdc_file_list.json",
                        "folderPath": "ecdc",
                        "container": "configslookup"
                    },
                    "encodingName": "UTF-8"
                },
                "schema": {}
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_ablobs_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_ecdc_raw_csv_http_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_http_ecdc_moein",
                    "type": "LinkedServiceReference",
                    "parameters": {
                        "sourceBaseURL": "@dataset().baseURL"
                    }
                },
                "parameters": {
                    "baseURL": {
                        "type": "String"
                    },
                    "relativeURL": {
                        "type": "String"
                    }
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "HttpServerLocation",
                        "relativeUrl": {
                            "value": "@dataset().relativeURL",
                            "type": "Expression"
                        }
                    },
                    "columnDelimiter": ",",
                    "rowDelimiter": "\n",
                    "encodingName": "UTF-8",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_http_ecdc_moein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/df_raw_cases_deaths_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": "cases_deaths.csv",
                        "folderPath": "ecdc",
                        "fileSystem": "rawmoein"
                    },
                    "columnDelimiter": "\t",
                    "rowDelimiter": "\n",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/df_processed_cases_deaths_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "folderPath": "ecdc/cases_death",
                        "fileSystem": "processedmoein"
                    },
                    "columnDelimiter": ",",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/df_country_lookup_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": "country_lookup.csv",
                        "fileSystem": "lookups"
                    },
                    "columnDelimiter": ",",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": [
                    {
                        "name": "country",
                        "type": "String"
                    },
                    {
                        "name": "country_code_2_digit",
                        "type": "String"
                    },
                    {
                        "name": "country_code_3_digit",
                        "type": "String"
                    },
                    {
                        "name": "continent",
                        "type": "String"
                    },
                    {
                        "name": "population",
                        "type": "String"
                    }
                ]
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_raw_hospital_admissions_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": "hospital_admissions.csv",
                        "folderPath": "ecdc",
                        "fileSystem": "rawmoein"
                    },
                    "columnDelimiter": "\t",
                    "rowDelimiter": "\n",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_dim_date_moein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": "dim_date.csv",
                        "fileSystem": "lookups"
                    },
                    "columnDelimiter": ",",
                    "rowDelimiter": "\n",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_processed_hospital_admissions_dailymoein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "folderPath": "ecdc/hospital_admissions_daily",
                        "fileSystem": "processedmoein"
                    },
                    "columnDelimiter": ",",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ds_processed_hospital_admissions_weeklymoein')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "ls_adls_covrepmoein",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "DelimitedText",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "folderPath": "ecdc/hospital_admissions_weekly",
                        "fileSystem": "processedmoein"
                    },
                    "columnDelimiter": ",",
                    "escapeChar": "\\",
                    "firstRowAsHeader": true,
                    "quoteChar": "\""
                },
                "schema": []
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/ls_adls_covrepmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/adf_trigger_blobevent_moein')]",
            "type": "Microsoft.DataFactory/factories/triggers",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "runtimeState": "Started",
                "pipelines": [
                    {
                        "pipelineReference": {
                            "referenceName": "pl_ingest_pop_moein",
                            "type": "PipelineReference"
                        },
                        "parameters": {}
                    }
                ],
                "type": "BlobEventsTrigger",
                "typeProperties": {
                    "blobPathBeginsWith": "/populationmoeinsource/",
                    "blobPathEndsWith": "population_by_age.tsv.gz",
                    "ignoreEmptyBlobs": true,
                    "scope": "[parameters('adf_trigger_blobevent_moein_properties_typeProperties_scope')]",
                    "events": [
                        "Microsoft.Storage.BlobCreated"
                    ]
                }
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/pipelines/pl_ingest_pop_moein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/tr_ingest_hospital_admissions_moein')]",
            "type": "Microsoft.DataFactory/factories/triggers",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "runtimeState": "Started",
                "pipelines": [
                    {
                        "pipelineReference": {
                            "referenceName": "pl_ingest_ecdc_moein",
                            "type": "PipelineReference"
                        },
                        "parameters": {}
                    }
                ],
                "type": "ScheduleTrigger",
                "typeProperties": {
                    "recurrence": {
                        "frequency": "Week",
                        "interval": 1,
                        "startTime": "2022-05-25T15:00:00Z",
                        "timeZone": "UTC"
                    }
                }
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/pipelines/pl_ingest_ecdc_moein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/ls_ablobs_covrepmoein')]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "type": "AzureBlobStorage",
                "typeProperties": {
                    "connectionString": "[variables('ls_ablobs_covrepmoein_connectionString')]"
                }
            },
            "dependsOn": []
        },
        {
            "name": "[concat(parameters('factoryName'), '/ls_adls_covrepmoein')]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "type": "AzureBlobFS",
                "typeProperties": {
                    "url": "[parameters('ls_adls_covrepmoein_properties_typeProperties_url')]",
                    "accountKey": {
                        "type": "SecureString",
                        "value": "[variables('ls_adls_covrepmoein_accountKey')]"
                    }
                }
            },
            "dependsOn": []
        },
        {
            "name": "[concat(parameters('factoryName'), '/ls_http_ecdc_moein')]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "parameters": {
                    "sourceBaseURL": {
                        "type": "String"
                    }
                },
                "annotations": [],
                "type": "HttpServer",
                "typeProperties": {
                    "url": "[parameters('ls_http_ecdc_moein_properties_typeProperties_url')]",
                    "enableServerCertificateValidation": true,
                    "authenticationType": "Anonymous"
                }
            },
            "dependsOn": []
        },
        {
            "name": "[concat(parameters('factoryName'), '/df_transform_cases_deaths_moein')]",
            "type": "Microsoft.DataFactory/factories/dataflows",
            "apiVersion": "2018-06-01",
            "properties": {
                "type": "MappingDataFlow",
                "typeProperties": {
                    "sources": [
                        {
                            "dataset": {
                                "referenceName": "df_raw_cases_deaths_moein",
                                "type": "DatasetReference"
                            },
                            "name": "CasesAndDeathsSource"
                        },
                        {
                            "dataset": {
                                "referenceName": "df_country_lookup_moein",
                                "type": "DatasetReference"
                            },
                            "name": "CountryLookup"
                        }
                    ],
                    "sinks": [
                        {
                            "dataset": {
                                "referenceName": "df_processed_cases_deaths_moein",
                                "type": "DatasetReference"
                            },
                            "name": "CasesAndDeathsSink"
                        }
                    ],
                    "transformations": [
                        {
                            "name": "FilterEuropeOnly"
                        },
                        {
                            "name": "SelectOnlyRequiredFields"
                        },
                        {
                            "name": "CreateYearAndWeekColumn"
                        },
                        {
                            "name": "PivotCounts"
                        },
                        {
                            "name": "lookupCountry"
                        },
                        {
                            "name": "PrepareForSink"
                        },
                        {
                            "name": "SortCountryDate"
                        }
                    ],
                    "scriptLines": [
                        "source(output(",
                        "          country as string,",
                        "          country_code as string,",
                        "          continent as string,",
                        "          population as integer,",
                        "          indicator as string,",
                        "          weekly_count as integer,",
                        "          year_week as string,",
                        "          rate_14_day as double,",
                        "          cumulative_count as integer,",
                        "          source as string,",
                        "          {{note} as string",
                        "     ),",
                        "     allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     ignoreNoFilesFound: false) ~> CasesAndDeathsSource",
                        "source(output(",
                        "          country as string,",
                        "          country_code_2_digit as string,",
                        "          country_code_3_digit as string,",
                        "          continent as string,",
                        "          population as integer",
                        "     ),",
                        "     allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     ignoreNoFilesFound: false) ~> CountryLookup",
                        "CasesAndDeathsSource filter(continent == \"Europe\" && not(isNull(country_code))) ~> FilterEuropeOnly",
                        "CreateYearAndWeekColumn select(mapColumn(",
                        "          country,",
                        "          country_code,",
                        "          population,",
                        "          indicator,",
                        "          weekly_count,",
                        "          cumulative_count,",
                        "          source,",
                        "          year,",
                        "          week",
                        "     ),",
                        "     skipDuplicateMapInputs: false,",
                        "     skipDuplicateMapOutputs: true) ~> SelectOnlyRequiredFields",
                        "FilterEuropeOnly derive(year = toInteger(at(split(year_week, \"-\"), 1)),",
                        "          week = toInteger(at(split(year_week, \"-\"), 2))) ~> CreateYearAndWeekColumn",
                        "SelectOnlyRequiredFields pivot(groupBy(country,",
                        "          country_code,",
                        "          population,",
                        "          source,",
                        "          year,",
                        "          week),",
                        "     pivotBy(indicator, ['cases', 'deaths']),",
                        "     count = sum(weekly_count),",
                        "     columnNaming: '$V_$N',",
                        "     lateral: true) ~> PivotCounts",
                        "PivotCounts, CountryLookup lookup(PivotCounts@country == CountryLookup@country,",
                        "     multiple: false,",
                        "     pickup: 'any',",
                        "     broadcast: 'auto')~> lookupCountry",
                        "SortCountryDate select(mapColumn(",
                        "          country = PivotCounts@country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          population = PivotCounts@population,",
                        "          cases_count,",
                        "          deaths_count,",
                        "          year,",
                        "          week,",
                        "          source",
                        "     ),",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true) ~> PrepareForSink",
                        "lookupCountry sort(desc(PivotCounts@country, true),",
                        "     desc(year, true),",
                        "     desc(week, true),",
                        "     partitionBy('hash', 1)) ~> SortCountryDate",
                        "PrepareForSink sink(allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     partitionFileNames:['cases_deaths.csv'],",
                        "     truncate: true,",
                        "     umask: 0022,",
                        "     preCommands: [],",
                        "     postCommands: [],",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true,",
                        "     partitionBy('hash', 1)) ~> CasesAndDeathsSink"
                    ]
                }
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/datasets/df_raw_cases_deaths_moein')]",
                "[concat(variables('factoryId'), '/datasets/df_country_lookup_moein')]",
                "[concat(variables('factoryId'), '/datasets/df_processed_cases_deaths_moein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/df_transform_hospital_admissions_moein')]",
            "type": "Microsoft.DataFactory/factories/dataflows",
            "apiVersion": "2018-06-01",
            "properties": {
                "type": "MappingDataFlow",
                "typeProperties": {
                    "sources": [
                        {
                            "dataset": {
                                "referenceName": "ds_raw_hospital_admissions_moein",
                                "type": "DatasetReference"
                            },
                            "name": "HospitalAdmissionsSource"
                        },
                        {
                            "dataset": {
                                "referenceName": "df_country_lookup_moein",
                                "type": "DatasetReference"
                            },
                            "name": "CountryLookup"
                        },
                        {
                            "dataset": {
                                "referenceName": "ds_dim_date_moein",
                                "type": "DatasetReference"
                            },
                            "name": "DimDate"
                        }
                    ],
                    "sinks": [
                        {
                            "dataset": {
                                "referenceName": "ds_processed_hospital_admissions_weeklymoein",
                                "type": "DatasetReference"
                            },
                            "name": "SinkHospitalsWeekly"
                        },
                        {
                            "dataset": {
                                "referenceName": "ds_processed_hospital_admissions_dailymoein",
                                "type": "DatasetReference"
                            },
                            "name": "SinkHospitalsDaily"
                        }
                    ],
                    "transformations": [
                        {
                            "name": "SelectReqFields"
                        },
                        {
                            "name": "LookupCountry"
                        },
                        {
                            "name": "SelectReqFields2"
                        },
                        {
                            "name": "SplitDailyFromWeekly"
                        },
                        {
                            "name": "AggDimDate"
                        },
                        {
                            "name": "JoinHospitalDimDate"
                        },
                        {
                            "name": "PivotDailyIndicator"
                        },
                        {
                            "name": "PivotWeeklyIndicator"
                        },
                        {
                            "name": "SortWeekly"
                        },
                        {
                            "name": "SortDaily"
                        },
                        {
                            "name": "SelectWeekly"
                        },
                        {
                            "name": "SelectDaily"
                        }
                    ],
                    "scriptLines": [
                        "source(output(",
                        "          country as string,",
                        "          indicator as string,",
                        "          date as date,",
                        "          year_week as string,",
                        "          value as double,",
                        "          source as string,",
                        "          {{url} as string",
                        "     ),",
                        "     allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     ignoreNoFilesFound: false) ~> HospitalAdmissionsSource",
                        "source(output(",
                        "          country as string,",
                        "          country_code_2_digit as string,",
                        "          country_code_3_digit as string,",
                        "          continent as string,",
                        "          population as long",
                        "     ),",
                        "     allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     ignoreNoFilesFound: false) ~> CountryLookup",
                        "source(output(",
                        "          date_key as date,",
                        "          date as date,",
                        "          year as string,",
                        "          month as short,",
                        "          day as short,",
                        "          day_name as string,",
                        "          day_of_year as short,",
                        "          week_of_month as short,",
                        "          week_of_year as string,",
                        "          month_name as string,",
                        "          year_month as integer,",
                        "          {{year_week} as integer",
                        "     ),",
                        "     allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     ignoreNoFilesFound: false) ~> DimDate",
                        "HospitalAdmissionsSource select(mapColumn(",
                        "          country,",
                        "          indicator,",
                        "          reported_date = date,",
                        "          reported_year_week = year_week,",
                        "          value,",
                        "          source",
                        "     ),",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true) ~> SelectReqFields",
                        "SelectReqFields, CountryLookup lookup(SelectReqFields@country == CountryLookup@country,",
                        "     multiple: false,",
                        "     pickup: 'any',",
                        "     broadcast: 'auto')~> LookupCountry",
                        "LookupCountry select(mapColumn(",
                        "          country = SelectReqFields@country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          indicator,",
                        "          population,",
                        "          reported_date,",
                        "          reported_year_week,",
                        "          value,",
                        "          source",
                        "     ),",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true) ~> SelectReqFields2",
                        "SelectReqFields2 split(indicator == \"Weekly new ICU admissions per 100k\" || indicator == \"Weekly new hospital admissions per 100k\",",
                        "     disjoint: false) ~> SplitDailyFromWeekly@(Weekly, Daily)",
                        "DimDate aggregate(groupBy(ecdc_year_week = year+\"-W\"+lpad(week_of_year,2,'0')),",
                        "     reported_week_start_date = min(date),",
                        "          reported_week_end_date = max(date)) ~> AggDimDate",
                        "SplitDailyFromWeekly@Weekly, AggDimDate join(reported_year_week == ecdc_year_week,",
                        "     joinType:'left',",
                        "     broadcast: 'auto')~> JoinHospitalDimDate",
                        "SplitDailyFromWeekly@Daily pivot(groupBy(country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          population,",
                        "          reported_date,",
                        "          reported_year_week,",
                        "          source),",
                        "     pivotBy(indicator, ['Daily hospital occupancy', 'Daily ICU occupancy']),",
                        "     count = sum(value),",
                        "     columnNaming: '$V_$N',",
                        "     lateral: true) ~> PivotDailyIndicator",
                        "JoinHospitalDimDate pivot(groupBy(country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          population,",
                        "          reported_date,",
                        "          reported_year_week,",
                        "          source,",
                        "          reported_week_start_date,",
                        "          reported_week_end_date),",
                        "     pivotBy(indicator, ['Weekly new ICU admissions per 100k', 'Weekly new hospital admissions per 100k']),",
                        "     count = sum(value),",
                        "     columnNaming: '$V_$N',",
                        "     lateral: true) ~> PivotWeeklyIndicator",
                        "PivotWeeklyIndicator sort(asc(country, true),",
                        "     desc(reported_date, true),",
                        "     partitionBy('hash', 1)) ~> SortWeekly",
                        "PivotDailyIndicator sort(asc(country, true),",
                        "     desc(reported_date, true),",
                        "     partitionBy('hash', 1)) ~> SortDaily",
                        "SortWeekly select(mapColumn(",
                        "          country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          population,",
                        "          reported_date,",
                        "          reported_year_week,",
                        "          reported_week_start_date,",
                        "          reported_week_end_date,",
                        "          new_icu_occupancy_count = {Weekly new ICU admissions per 100k_count},",
                        "          new_hospital_occupancy_count = {Weekly new hospital admissions per 100k_count},",
                        "          source",
                        "     ),",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true) ~> SelectWeekly",
                        "SortDaily select(mapColumn(",
                        "          country,",
                        "          country_code_2_digit,",
                        "          country_code_3_digit,",
                        "          population,",
                        "          reported_date,",
                        "          reported_year_week,",
                        "          hospital_occupancy_count = {Daily hospital occupancy_count},",
                        "          icu_occupancy_count = {Daily ICU occupancy_count},",
                        "          source",
                        "     ),",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true) ~> SelectDaily",
                        "SelectWeekly sink(allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     partitionFileNames:['hospitals_admissions_weekly.csv'],",
                        "     truncate: true,",
                        "     umask: 0022,",
                        "     preCommands: [],",
                        "     postCommands: [],",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true,",
                        "     partitionBy('hash', 1)) ~> SinkHospitalsWeekly",
                        "SelectDaily sink(allowSchemaDrift: true,",
                        "     validateSchema: false,",
                        "     partitionFileNames:['hospitals_admissions_daily.csv'],",
                        "     truncate: true,",
                        "     umask: 0022,",
                        "     preCommands: [],",
                        "     postCommands: [],",
                        "     skipDuplicateMapInputs: true,",
                        "     skipDuplicateMapOutputs: true,",
                        "     partitionBy('hash', 1)) ~> SinkHospitalsDaily"
                    ]
                }
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/datasets/ds_raw_hospital_admissions_moein')]",
                "[concat(variables('factoryId'), '/datasets/df_country_lookup_moein')]",
                "[concat(variables('factoryId'), '/datasets/ds_dim_date_moein')]",
                "[concat(variables('factoryId'), '/datasets/ds_processed_hospital_admissions_weeklymoein')]",
                "[concat(variables('factoryId'), '/datasets/ds_processed_hospital_admissions_dailymoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/pl_ingest_pop_moein')]",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "apiVersion": "2018-06-01",
            "properties": {
                "activities": [
                    {
                        "name": "Check if file exists",
                        "type": "Validation",
                        "dependsOn": [],
                        "userProperties": [],
                        "typeProperties": {
                            "dataset": {
                                "referenceName": "ds_population_moein_gz",
                                "type": "DatasetReference",
                                "parameters": {}
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
                                "referenceName": "ds_population_moein_gz",
                                "type": "DatasetReference",
                                "parameters": {}
                            },
                            "fieldList": [
                                "columnCount",
                                "size",
                                "exists"
                            ],
                            "storeSettings": {
                                "type": "AzureBlobStorageReadSettings",
                                "recursive": true,
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
                                    "name": "Send email on failure",
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
                                        "url": "https://prod-48.eastus.logic.azure.com:443/workflows/9c8b32b2d1f64269b1875eac417cb4be/triggers/some-http-trigger/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fsome-http-trigger%2Frun&sv=1.0&sig=eztiadWZqnquGmsMx8JkAOoe5SbaCHigcZAtnzv3x8w",
                                        "method": "POST",
                                        "headers": {},
                                        "body": {
                                            "value": "{\"EmailTo\": \"@{pipeline().parameters.EmailTo}\",\"Subject\": \"Reload for @{pipeline().Pipeline}-pipeline completed\",\"FactoryName\": \"@{pipeline().DataFactory}\",\"PipelineName\": \"@{pipeline().Pipeline}\",\"ActivityName\": \"@{pipeline().parameters.ActivityName}\",\"Message\": \"@{pipeline().parameters.Message}\"}\n",
                                            "type": "Expression"
                                        }
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
                                            "referenceName": "ds_population_moein_gz",
                                            "type": "DatasetReference",
                                            "parameters": {}
                                        }
                                    ],
                                    "outputs": [
                                        {
                                            "referenceName": "ds_population_moein_tsv",
                                            "type": "DatasetReference",
                                            "parameters": {}
                                        }
                                    ]
                                },
                                {
                                    "name": "Delete Source File",
                                    "type": "Delete",
                                    "dependsOn": [
                                        {
                                            "activity": "Copy Population Data",
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
                                            "referenceName": "ds_population_moein_gz",
                                            "type": "DatasetReference",
                                            "parameters": {}
                                        },
                                        "enableLogging": false,
                                        "storeSettings": {
                                            "type": "AzureBlobStorageReadSettings",
                                            "recursive": true,
                                            "enablePartitionDiscovery": false
                                        }
                                    }
                                }
                            ]
                        }
                    }
                ],
                "concurrency": 1,
                "policy": {
                    "elapsedTimeMetric": {},
                    "cancelAfter": {}
                },
                "parameters": {
                    "ActivityName": {
                        "type": "String",
                        "defaultValue": "Copying Data"
                    },
                    "EmailTo": {
                        "type": "String",
                        "defaultValue": "moin.torabi@gmail.com"
                    },
                    "Message": {
                        "type": "String",
                        "defaultValue": "There's an error regarding the number of columns!"
                    }
                },
                "annotations": [],
                "lastPublishTime": "2022-06-07T16:53:04Z"
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/datasets/ds_population_moein_gz')]",
                "[concat(variables('factoryId'), '/datasets/ds_population_moein_tsv')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/pl_ingest_ecdc_moein')]",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "apiVersion": "2018-06-01",
            "properties": {
                "activities": [
                    {
                        "name": "Lookup ECDC File List",
                        "type": "Lookup",
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
                            "source": {
                                "type": "JsonSource",
                                "storeSettings": {
                                    "type": "AzureBlobStorageReadSettings",
                                    "recursive": true,
                                    "enablePartitionDiscovery": false
                                },
                                "formatSettings": {
                                    "type": "JsonReadSettings"
                                }
                            },
                            "dataset": {
                                "referenceName": "ds_ecdc_filelist_moein",
                                "type": "DatasetReference",
                                "parameters": {}
                            },
                            "firstRowOnly": false
                        }
                    },
                    {
                        "name": "Execute Copy For Every Record",
                        "type": "ForEach",
                        "dependsOn": [
                            {
                                "activity": "Lookup ECDC File List",
                                "dependencyConditions": [
                                    "Succeeded"
                                ]
                            }
                        ],
                        "userProperties": [],
                        "typeProperties": {
                            "items": {
                                "value": "@activity('Lookup ECDC File List').output.value",
                                "type": "Expression"
                            },
                            "activities": [
                                {
                                    "name": "Copy ECDC Data",
                                    "type": "Copy",
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
                                        "source": {
                                            "type": "DelimitedTextSource",
                                            "storeSettings": {
                                                "type": "HttpReadSettings",
                                                "requestMethod": "GET"
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
                                            "referenceName": "ds_ecdc_raw_csv_http_moein",
                                            "type": "DatasetReference",
                                            "parameters": {
                                                "baseURL": {
                                                    "value": "@item().sourceBaseURL",
                                                    "type": "Expression"
                                                },
                                                "relativeURL": {
                                                    "value": "@item().sourceRelativeURL",
                                                    "type": "Expression"
                                                }
                                            }
                                        }
                                    ],
                                    "outputs": [
                                        {
                                            "referenceName": "ds_ecdc_raw_csv_http_dlmoein",
                                            "type": "DatasetReference",
                                            "parameters": {
                                                "fileName": {
                                                    "value": "@item().sinkFileName",
                                                    "type": "Expression"
                                                }
                                            }
                                        }
                                    ]
                                }
                            ]
                        }
                    }
                ],
                "concurrency": 1,
                "policy": {
                    "elapsedTimeMetric": {},
                    "cancelAfter": {}
                },
                "annotations": [],
                "lastPublishTime": "2022-06-07T16:53:04Z"
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/datasets/ds_ecdc_filelist_moein')]",
                "[concat(variables('factoryId'), '/datasets/ds_ecdc_raw_csv_http_moein')]",
                "[concat(variables('factoryId'), '/datasets/ds_ecdc_raw_csv_http_dlmoein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/pl_process_cases_deaths_moein')]",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "apiVersion": "2018-06-01",
            "properties": {
                "activities": [
                    {
                        "name": "df_transform_cases_deaths_moein",
                        "type": "ExecuteDataFlow",
                        "dependsOn": [],
                        "policy": {
                            "timeout": "1.00:00:00",
                            "retry": 0,
                            "retryIntervalInSeconds": 30,
                            "secureOutput": false,
                            "secureInput": false
                        },
                        "userProperties": [],
                        "typeProperties": {
                            "dataflow": {
                                "referenceName": "df_transform_cases_deaths_moein",
                                "type": "DataFlowReference",
                                "parameters": {},
                                "datasetParameters": {
                                    "CasesAndDeathsSource": {},
                                    "CountryLookup": {},
                                    "CasesAndDeathsSink": {}
                                }
                            },
                            "staging": {},
                            "compute": {
                                "coreCount": 8,
                                "computeType": "General"
                            },
                            "traceLevel": "Fine"
                        }
                    }
                ],
                "concurrency": 1,
                "policy": {
                    "elapsedTimeMetric": {},
                    "cancelAfter": {}
                },
                "annotations": [],
                "lastPublishTime": "2022-06-07T16:53:04Z"
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/dataflows/df_transform_cases_deaths_moein')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/pl_process_hospital_admissions_moein')]",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "apiVersion": "2018-06-01",
            "properties": {
                "activities": [
                    {
                        "name": "df_transform_hospital_admissions_moein",
                        "type": "ExecuteDataFlow",
                        "dependsOn": [],
                        "policy": {
                            "timeout": "1.00:00:00",
                            "retry": 0,
                            "retryIntervalInSeconds": 30,
                            "secureOutput": false,
                            "secureInput": false
                        },
                        "userProperties": [],
                        "typeProperties": {
                            "dataflow": {
                                "referenceName": "df_transform_hospital_admissions_moein",
                                "type": "DataFlowReference",
                                "parameters": {},
                                "datasetParameters": {
                                    "HospitalAdmissionsSource": {},
                                    "CountryLookup": {},
                                    "DimDate": {},
                                    "SinkHospitalsWeekly": {},
                                    "SinkHospitalsDaily": {}
                                }
                            },
                            "staging": {},
                            "compute": {
                                "coreCount": 8,
                                "computeType": "General"
                            },
                            "traceLevel": "Fine"
                        }
                    }
                ],
                "policy": {
                    "elapsedTimeMetric": {},
                    "cancelAfter": {}
                },
                "annotations": [],
                "lastPublishTime": "2022-06-08T08:06:11Z"
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/dataflows/df_transform_hospital_admissions_moein')]"
            ]
        }
    ]
}
  JSON
}