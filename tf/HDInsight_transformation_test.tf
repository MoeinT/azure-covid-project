#Create a managed identity to give access to different resources
resource "azurerm_user_assigned_identity" "covid-user-assigned-identity" {
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  location            = azurerm_resource_group.covid-reporting-rg.location

  name = "covid-user-assigned-identity-${local.my_name}"
}


#Filesystem within datalake for our Hadoop cluster
resource "azurerm_storage_data_lake_gen2_filesystem" "hadoop-file-system" {
  name               = "hadoop-filesystem-dlsa-${local.my_name}"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Container within storage account for our Haddop cluster
resource "azurerm_storage_container" "haddop-cluster" {
  name                  = "hadoop-container-sa-${local.my_name}"
  storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
  container_access_type = "private"
}

#Creating a Hadoop Cluster with HDInsight 

# resource "azurerm_hdinsight_hadoop_cluster" "example" {
#   name                = "covidrep-hdi-${local.my_name}"
#   resource_group_name = azurerm_resource_group.covid-reporting-rg.name
#   location            = azurerm_resource_group.covid-reporting-rg.location
#   cluster_version     = "3.6"
#   tier                = "Standard"

#   component_version {
#     hadoop = "3.1.0"
#   }

#   gateway {
#     username = "moein"
#     password = "Moin2010!!!"
#   }

#   storage_account_gen2 {
#     storage_resource_id          = azurerm_storage_account.covid-reporting-sa-dl.id
#     filesystem_id                = azurerm_storage_data_lake_gen2_filesystem.hadoop-file-system.id
#     managed_identity_resource_id = azurerm_user_assigned_identity.covid-user-assigned-identity.id
#     is_default                   = true
#   }


#   storage_account {
#     storage_container_id = azurerm_storage_container.haddop-cluster.id
#     storage_account_key  = azurerm_storage_account.covid-reporting-sa.primary_access_key
#     is_default           = false
#   }

#   roles {
#     head_node {
#       vm_size  = "A5"
#       username = "acctestusrvm1"
#       #password = "AccTestvdSC4daf986!"
#     }

#     worker_node {
#       vm_size               = "A5"
#       username              = "acctestusrvm2"
#       #password              = "BccTestvdSC4daf986!"
#       target_instance_count = 2
#     }

#     zookeeper_node {
#       vm_size  = "A5"
#       username = "acctestusrvm3"
#       #password = "CccTestvdSC4daf986!"
#     }
#   }
# }