# ohi_regional_stats.r

# by JSL July 23 2013. 
# pull statistics for some regional assessments

## setup ----
source('../ohiprep/src/R/common.R') # set dir_neptune_data
# library(stringr)
library(tools)
# library(reshape2)

# read in coastal pop from Neptune for 2013
c = read.csv(file.path(dir_neptune_data, 'model/GL-NCEAS-CoastalPopulation_v2013/data', 
                       'cntry_popsum2013_inland25mi_complete.csv')); head(c)


## read in regional assessments ----
nonCountry = c('U.S. West Coast', 'Baltic Sea', 'Hawaii')

RAs = read.csv('../ohiprep/tmp/ohi_regional/rgns_regional.csv') %>%
  select(rgn_nam = region,
         status) %>%
  filter(!rgn_nam %in% nonCountry) %>%
  left_join(read.csv('../ohi-global/eez2013/layers/rgn_global.csv') %>%
              select(rgn_id, 
                     rgn_nam = label),
            by='rgn_nam') %>%
  select(rgn_nam, rgn_id, status) %>%
  arrange(status, rgn_nam); head(RAs)

# read in layers of interest from layers.csv
loi = list(
  'area_eez'     = 'rgn_area',
  'coastal_jobs' = 'le_jobs_cur_adj_value',
  'coastal_rev'  = 'le_rev_cur_adj_value')

layers = read.csv('../ohi-global/eez2013/layers.csv') %>%
  filter(layer %in% loi)


# loop through, read in and pull out only the regional assessments ---- 
if (exists('d')) rm(d)
for (i in 1:length(layers$filename)) { # i=1
  
  l = read.csv(file.path('../ohi-global/eez2013/layers', layers$filename[i])); head(l)
  nam = names(loi)[loi == file_path_sans_ext(layers$filename[i])]
  
  # rename 'value' field
  names(l)[!names(l) %in% c('rgn_id', 'cntry_key', 'sector', 'category')] = 'value'
  
  # save a coyp
  l2 = l 
  
  # if cntry_key, translate to rgn_id
  if ('cntry_key' %in% names(l)){
    
    lf = l %>%
      left_join(c,
                by = 'cntry_key') %>% 
      filter(!cntry_key %in% c('ATA', 'ANT'))    
    lf$rgn_id[lf$cntry_key == 'ABW'] = 250 # Aruba
    lf$rgn_id[lf$cntry_key == 'BRN'] = 247 # Brunei
    lf$rgn_id[lf$cntry_key == 'HKG'] = 209 # Hong Kong 
    lf$rgn_id[lf$cntry_key == 'MNE'] = 186 # Montenegro
    lf$rgn_id[lf$cntry_key == 'MYS'] = 206 # Malaysia
    
    l2 = lf %>%
      select(rgn_id, sector, value)        
  }
  
  # sum by rgn_id, add layer indicator
  h = l2 %>% 
    group_by(rgn_id) %>%
    summarize(value = sum(value, na.rm=T)) %>% # just need to sum by rgn_id
    mutate(layer = nam) %>%
    arrange(rgn_id); head(h); summary(h) 
  
  # rbind
  if (!exists('d')){
    d = h
  } else {
    d = rbind(d, h)
  }
}
head(d)

## coastal pop and coastal inland area from Neptune ----
cp = c %>%
  select(rgn_id, 
         value = cntry_popsum2013_inland25mi) %>%
  mutate(layer = 'coastal_pop')

ca = c %>%
  select(rgn_id, 
         value = area_km2) %>%
  mutate(layer = 'area_inland25km')

cl = read.csv(file.path(dir_neptune_data, 'model/GL-NCEAS-OceanRegions_v2013a/data', 
                        'rgn_area_inland1km.csv')) %>%
  select(rgn_id, 
         value = area_km2) %>%
  mutate(layer = 'area_inland1km')

# coastline length from Neptune
#...must id this file


## combine all data layers and 
h_g = rbind(d, ca, cp, cl) %>%
  group_by(rgn_id, layer) %>%
  summarize(value = sum(value, na.rm = T)) %>% # stopifnot(anyDuplicated(h_g[,c('rgn_id', 'layer')]) == 0)
  dcast(rgn_id ~ layer, value.var = 'value') %>%
  select(rgn_id, area_eez, area_inland1km, area_inland25km, coastal_pop, coastal_jobs, coastal_rev); head(h_g)



## save ----
f_out = '../ohiprep/tmp/ohi_regional/regional_stats'


# save global sum
hb_globalsum <- data.frame(t(colSums(h_g, na.rm=T))); hb_globalsum
write.csv(hb_globalsum, paste(f_out, '_globalsum.csv', sep = ''), row.names = F, na = '')

# save only regional assessments
h_ra = h_g %>%
  filter(rgn_id %in% RAs$rgn_id) %>%
  left_join(RAs, by = 'rgn_id') %>%
  select(rgn_nam, status, area_eez, area_inland1km, area_inland25km, coastal_pop, coastal_jobs, coastal_rev); head(h_ra)


# add 2 eezs by hand from Wikipedia: http://en.wikipedia.org/wiki/Exclusive_economic_zone#United_States
h_ra2 = rbind(h_ra, 
            data.frame(rgn_nam = 'US West Coast', status='current', area_eez=895346+1579538, 
                       area_inland1km=NA, area_inland25km=NA, coastal_jobs=NA, coastal_pop=NA, coastal_rev=NA),
            data.frame(rgn_nam = 'Hawaii', status='current', area_eez=825549, 
                       area_inland1km=NA, area_inland25km=NA, coastal_jobs=NA, coastal_pop=NA, coastal_rev=NA)) %>%
  arrange(status, rgn_nam); h_ra2

write.csv(h_ra2, paste(f_out, '.csv', sep = ''), row.names = F, na = '')


# save regional assessment sum
h_racurrent_sum <- data.frame(t(colSums(h_ra2 %>% 
                                          filter(status == 'current') %>%
                                          select(-rgn_nam, -status),
                                        na.rm=T))); h_racurrent_sum
write.csv(h_racurrent_sum, paste(f_out, '_currentRAsum.csv', sep = ''), row.names = F, na = '')


# a few calculations:
p = as.numeric(h_racurrent_sum$area_eez/hb_globalsum$area_eez *100 )
cat(sprintf('Currently, OHI covers %f percent of global EEZs for the benefit of %d people', 
            p, h_racurrent_sum$coastal_pop))


# --- fin ---

