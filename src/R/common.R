
# set the neptune data_edit share based on operating system
dir_neptune_data = c('Windows' = '//neptune.nceas.ucsb.edu/data_edit',
                     'Darwin'  = '/Volumes/data_edit',
                     'Linux'   = '/var/data/ohi')[[ Sys.info()[['sysname']] ]]

dir_neptune_local = c('Windows' = '//neptune.nceas.ucsb.edu/local_edit',
                      'Darwin'  = '/Volumes/local_edit',
                      'Linux'   = '/usr/local/ohi')[[ Sys.info()[['sysname']] ]]

dir_halpern2008 = c('Windows' = '//neptune.nceas.ucsb.edu/halpern2008_edit',
                    'Darwin'  = '/Volumes/halpern2008_edit',
                    'Linux'   = '/var/cache/halpern-et-al')[[ Sys.info()[['sysname']] ]]

# stop if directory doesn't exist
if (!file.exists(sprintf('%s/',dir_neptune_data))){
  stop(sprintf("The directory for variable dir_neptune_data set in src/R/common.R does not exist. Do you need to mount %s?", dir_neptune_data))
  
}

# load commonly used libraries'
library(reshape2)
library(plyr)
library(dplyr)