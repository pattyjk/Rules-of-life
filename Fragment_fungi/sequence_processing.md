## Fragment fungi 
 ```
#import paired end reads for RoL run1
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/RoL_ITS_Run1
qiime tools import --type EMPPairedEndSequences --input-path data   --output-path RoL_run1_seqs.qza
  
#demultiplex reads for RoL Run 1
qiime demux emp-paired  --i-seqs RoL_run1_seqs.qza  --m-barcodes-file RoL_Run1_map.txt  --m-barcodes-column BarcodeSequence  --o-per-sample-sequences RoL_Run1_demux.qza   --o-error-correction-details demux-details_RoL_Run1.qza   --p-no-golay-error-correction   --p-rev-comp-mapping-barcodes
  
#export fastq reads per sample for run1 
qiime tools export --input-path RoL_Run1_demux.qza --output-path run2_demux_fastq
  
#import paired end reads for RoL run2
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/RoL_ITS_Run2
qiime tools import --type EMPPairedEndSequences --input-path data --output-path RoL_run2_seqs.qza

#demultiplex reads for RoL Run 2
qiime demux emp-paired  --i-seqs RoL_run2_seqs.qza  --m-barcodes-file RoL_Run2_map.txt  --m-barcodes-column BarcodeSequence  --o-per-sample-sequences RoL_Run2_demux.qza   --o-error-correction-details demux-details_RoL_Run2.qza   --p-no-golay-error-correction   --p-rev-comp-mapping-barcodes

#export fastq reads per sample for run2
qiime tools export --input-path RoL_Run2_demux.qza --output-path run2_demux_fastq

#reimport fastq files to make a master seq of sequences for all RoL samples
qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path RoL_manifest.txt \
 --output-path RoL_seqs_full.qza \
 --input-format PairedEndFastqManifestPhred33V2

#join paired end reads with vsearch
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs RoL_seqs_full.qza \
  --o-merged-sequences RoL_ITS_joined.qza 

#quality filter joined reads
qiime quality-filter q-score \
--i-demux  RoL_ITS_joined.qza \
--o-filtered-sequences  RoL_ITS_filt.qza \
--o-filter-stats  RoL_ITS_filt_stats.qza \
--p-min-quality 30

#dereplicate sequences with vsearch
qiime vsearch dereplicate-sequences \
--i-sequences RoL_ITS_filt.qza \
--o-dereplicated-table RoL_derep_table.qza \
--o-dereplicated-sequences RoL_derep_seqs.qza

#call OTUs at 97% with vsearch
 qiime vsearch cluster-features-de-novo \
  --i-sequences RoL_derep_seqs.qza \
 --i-table RoL_derep_table.qza \
 --p-perc-identity 0.97 \
  --o-clustered-table RoL_vsearch_otu_table.qza \
 --o-clustered-sequences RoL_vearch_rep_seqs.qza

#process with DADA2
qiime dada2 denoise-paired \
 --i-demultiplexed-seqs RoL__seqs_full.qza \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 150 \
  --p-trunc-len-r 150 \
  --o-table RoL_dada2_table.qza \
 --o-representative-sequences RoL_dada2_rep-seqs.qza \
 --o-denoising-stats RoL_dada2_denoising-stats.qza
```

# Assign taxonomy
```
#pull qiime formatted QIIME databse: https://doi.plutof.ut.ee/doi/10.15156/BIO/2938079

#decompress
tar xzf FB78E30E44793FB02E5A4D3AE18EB4A6621A2FAEB7A4E94421B8F7B65D46CA4A.tgz

#move to directory
mkdir unite_v9
mv sh* unite_v9
rm FB78E30E44793FB02E5A4D3AE18EB4A6621A2FAEB7A4E94421B8F7B65D46CA4A.tgz

#Fix formatting errors that prevent importation of the reference sequences into QIIME2. There are white spaces that interfere, and possibly some lower case letters that need to be converted to upper case.

awk '/^>/ {print($0)}; /^[^>]/ {print(toupper($0))}' unite_v9/sh_refs_qiime_ver9_99_25.07.2023.fasta | tr -d ' ' > unite_v9/sh_refs_qiime_ver9_99_25.07.2023_uppercase.fasta

#Import the UNITE reference sequences into QIIME2.
qiime tools import \
--type FeatureData[Sequence] \
--input-path unite_v9/sh_refs_qiime_ver9_99_25.07.2023_uppercase.fasta \
--output-path unite-ver9-seqs_99.qza

#Import the taxonomy file.
qiime tools import \
--type FeatureData[Taxonomy] \
--input-path unite_v9/sh_taxonomy_qiime_ver9_99_25.07.2023.txt \
--output-path unite-ver9-taxonomy_99.qza \
--input-format HeaderlessTSVTaxonomyFormat

#Train the classifier.
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS
qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads unite-ver9-seqs_99.qza \
--i-reference-taxonomy unite-ver9-taxonomy_99.qza \
--o-classifier unite-ver9-99-classifier.qza

cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/RoL_data

#Assign taxonomy with sklearn/UNITE v9
qiime feature-classifier classify-sklearn
--i-classifier /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/unite-ver9-99-classifier.qza \
--p-n-jobs 24 \
--i-reads RoL_dada2_rep-seqs.qza \
--o-classification dada2_tax.qza

qiime feature-classifier classify-sklearn
--i-classifier /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/unite-ver9-99-classifier.qza \
--p-n-jobs 24 \
--i-reads RoL_vearch_rep_seqs.qza \
--o-classification vsearch_tax.qza

#make taxa barplots
qiime taxa barplot --o-visualization vsearch_taxa_plot.qzv --m-metadata-file Rol_full_map.txt --i-table RoL_vsearch_otu_table.qza --i-taxonomy vsearch_tax.qza

qiime taxa barplot --o-visualization dada2_taxa_plot.qzv --m-metadata-file Rol_full_map.txt --i-table RoL_dada2_table.qza --i-taxonomy dada2_tax.qza

```


## Export OTU tables to text/biom files
```
qiime tools export --input-path RoL_dada2_table.qza --output-path dada2_table
qiime tools export --input-path RoL_vsearch_otu_table.qza --output-path vsearch_table

biom convert -i vsearch_table/feature-table.biom -o vsearch_otu_table.txt --to-tsv
biom convert -i dada2_table/feature-table.biom -o dada2_otu_table.txt --to-tsv


```