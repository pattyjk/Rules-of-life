#'frag_Denborda': this metric is used as a proxy to assess the 'edge effect' in the fragments. This is relatively a new metric so we have been including it to see if it makes sense biologically.

#'frag_Split_pond' and 'frag_Split_Stream_2nd': these are the habitat split metrics. These metrics pretty much represent the mean of the distance from a forest fragment to the closest water bodies (pond/s and second order streams) in the four cardinal directions (N, S, E and W).

#land_percent_CobVeg: this is the percentage of forest cover at the landscape-level (within each landscape there are five study forest fragments). This metric is interesting, but it is negatively correlated with habitat split, so that is something to keep in mind.

setwd("/Users/patty/OneDrive/Documents/GitHub/Brazil_RoL/")

##read in table
#normalized table
norm_pc<-read.delim("pred_metagenome_unstrat_normalized.tsv", header=T, row.names=1)

#unnormailzed table
nonorm_pc<-read.delim("pred_metagenome_unstrat_no_norm.tsv", row.names=1, header=T)

#divide table
div_pc<-nonorm_pc/norm_pc

#calculate weighted mean
asv_means<-as.data.frame(colMeans(na.omit(div_pc)))
asv_means$SampleID<-row.names(asv_means)
names(asv_means)<-c("Weighted_operon", "SampleID")

#read metadata
meta<-read.delim("metadata.txt", header=T)

#append meta to operon no
asv_means<-merge(asv_means, meta, by='SampleID')

#plot stuff
library(ggplot2)
library(ggpubr)

ggplot(asv_means, aes(species, Final_Bd_Load_log))+
         geom_boxplot()+
  scale_y_log10()+
  coord_flip()

#haddadus doesn't have any Bd

ggplot(asv_means, aes(Final_Bd_Load_log, Weighted_operon, color=species))+
 # geom_point()+
  theme_bw()+
  stat_cor(method = "spearman", cor.coef.name="rho")+
 # facet_wrap(~species)+
  ylab("Mean weighted Operon Number")+
  geom_smooth(method = 'lm')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(asv_means, aes(species, Weighted_operon, color=species))+
 geom_boxplot()+
  ylab("Mean weighted Operon Number")+
  theme_bw()+
  coord_flip()+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))
  
pairwise.t.test(asv_means$Weighted_operon, asv_means$species)
#almost all comparisons are significant, so differs between species

ggplot(asv_means, aes(frag_Denborda, Weighted_operon, color=species))+
 # geom_point()+
  theme_bw()+
  ylab("Mean weighted Operon Number")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  geom_smooth(method = 'lm')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(asv_means, aes(land_percent_CobVeg, Weighted_operon, color=species))+
  #geom_point()+
  theme_bw()+
  ylab("Mean Weighted Operon Number")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
    geom_smooth(method = 'lm')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(asv_means, aes(frag_Split_Stream_2nd, Weighted_operon, color=species))+
 # geom_point()+
  theme_bw()+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  ylab("Mean weighted Operon Number")+
  geom_smooth(method = 'lm')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(asv_means, aes(frag_Split_pond, Weighted_operon, color=species))+
 # geom_point()+
  theme_bw()+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  ylab("Mean weighted Operon Number")+
  ylim(c(0,2.5))+
  geom_smooth(method = 'lm')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))


####look at BSG clusters
library(ggplot2)
library(plyr)
library(reshape2)

#read in data
norm_pc<-read.delim("pred_metagenome_unstrat_normalized.tsv", header=T)
full_kegg<-read.delim("full_kegg.txt", header=T)
meta<-read.delim("metadata.txt", header=T)
bsg_ko<-read.delim("bsg_KO.txt", header=T)
dim(bsg_ko)
#310 x 1

#merge tables to filter out no BSG KOs
bsg_table<-merge(norm_pc, bsg_ko, all.x=F, all.y=T, by.y='KO', by.x='function.')
dim(bsg_table)
#310 x 667

#reshape table and merge metadata and add KEGG
bsg_table_m<-melt(bsg_table)
bsg_table_m<-merge(bsg_table_m, meta, by.y='SampleID', by.x='variable')
bsg_table_m<-merge(bsg_table_m, full_kegg, by.x='function.', by.y="KO", all.y=F)

ggplot(bsg_table_m, aes(land_percent_CobVeg, value, color=species))+
  #geom_point()+
  scale_y_log10()+
  theme_bw()+
  ylab("Log10 abundance- BSG KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  geom_smooth(method = 'lm')+
  facet_wrap(~Level3)+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(bsg_table_m, aes(Final_Bd_Load_log, value,  color=species))+
  #geom_point()+
  #scale_y_log10()+
  theme_bw()+
  ylab("Log10 abundance- BSG KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  geom_smooth(method = 'lm')+
  facet_wrap(~Level3, drop=T, scales='free')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(bsg_table_m, aes(land_DenBorda, value, color=species))+
 # geom_point()+
  scale_y_log10()+
  geom_smooth(method = 'lm')+
  theme_bw()+
  ylab("Log10 abundance- BSG KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  facet_wrap(~Level2)+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(bsg_table_m, aes(frag_Split_pond, value, color=species))+
  #geom_point()+
  scale_y_log10()+
  geom_smooth(method = 'lm')+
  theme_bw()+
  ylab("Log10 abundance- BSG KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  facet_wrap(~Level3)+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(bsg_table_m, aes(frag_Split_Stream_2nd, value, color=species))+
  #geom_point()+
  scale_y_log10()+
  geom_smooth(method = 'lm')+
  theme_bw()+
  ylab("Log10 abundance- BSG KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  facet_wrap(~Level3)+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))


##look at dormancy genes
#read in data
dorm_ko<-read.delim("dorm_KO.txt", header=T)
meta<-read.delim("metadata.txt", header=T)
dim(dorm_ko)
#119 x 2
dorm_ko2<-as.data.frame(dorm_ko[,-2])
names(dorm_ko2)<-"KO"
nonorm_pc<-read.delim("pred_metagenome_unstrat_normalized.tsv", header=T)

#convert to relative abundance
#nonorm_pc<-sweep(nonorm_pc, 2, colSums(nonorm_pc), '/')
#nonorm_pc$function.<-row.names(nonorm_pc)

#merge tables to filter out not dorm KOs
dorm_table<-merge(nonorm_pc, dorm_ko2, all.x=F, all.y=T, by.y='KO', by.x='function.')

#reshape table and merge metadata
dorm_table_m<-melt(dorm_table)
dorm_table_m<-merge(dorm_table_m, meta, by.y='SampleID', by.x='variable')
dorm_table_m<-merge(dorm_table_m, full_kegg, by.x='function.', by.y="KO", all.y=F, all.x=T)
dorm_table_m<-merge(dorm_table_m, dorm_ko, by.x = 'function.', by.y='KO', all.x=F, all.y=F)

#remove Bokermannohyla
#dorm_table_m<- dorm_table_m[-which(dorm_table_m$species == "Bokermannohyla hylax" | dorm_table_m$species == "Bokermannohyla circumdata"),]

#remove weird duplicates
library(dplyr)
dorm_table_m <- dorm_table_m %>% distinct()

#write and read back in table to edit weird NAs out that won't go away
write.table(dorm_table_m, 'dorm_table.txt', row.names=F, quote=F, sep='\t')
dorm_table_m<-read.delim('dorm_table.txt', header=T)

ggplot(dorm_table_m, aes(as.numeric(land_percent_CobVeg), as.numeric(rel_abun), color=species))+
 #geom_point()+
  #scale_y_log10()+
  theme_bw()+
  ylab("Relative abundance- Dormancy KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  geom_smooth(method = 'lm')+
  xlab("Percent forest cover")+
  facet_wrap(~Type, scales='free_y')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(dorm_table_m, aes(Final_Bd_Load_log, value, color=species))+
  #geom_point()+
 #scale_y_log10()+
  theme_bw()+
  ylab("Abundance- Dormancy KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  geom_smooth(method = 'lm')+
  facet_wrap(~Type, scales ='free_y')+
  xlab("Log10 Bd load")+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(dorm_table_m, aes(land_DenBorda, value, color=species))+
  #geom_point()+
 # scale_y_log10()+
  geom_smooth(method = 'lm')+
  theme_bw()+
  xlab("DenBorda")+
  ylab("Log10 abundance- Dormancy KO")+
  stat_cor(method = "spearman", cor.coef.name="rho")+
  facet_wrap(~Type, scales ='free_y')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(dorm_table_m, aes(frag_Split_pond, value, color=species))+
  #geom_point()+
  #scale_y_log10()+
  ylab("Abundance- Dormancy KO")+
  stat_cor(method = "spearman", cor.coef.name = 'rho')+
  geom_smooth(method = 'lm')+
  theme_bw()+
  xlab("Habitat split- pond")+
  facet_wrap(~Type, scales='free_y')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))

ggplot(dorm_table_m, aes(frag_Split_Stream_2nd, value, color=species))+
 #geom_point()+
  #scale_y_log10()+
  geom_smooth(method = 'lm')+
  theme_bw()+
  xlab("Habitat split- stream")+
  ylab("Abundance- Dormancy KO")+
 # stat_cor(method = "kendall", cor.coef.name="rho")+
  facet_wrap(~Type, scales='free_y')+
  scale_color_manual(values=c("black", "red", "grey", "blue", "orange", "green"))



