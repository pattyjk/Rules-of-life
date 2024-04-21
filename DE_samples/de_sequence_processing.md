## Sequence processing

```
#import paired end reads for DE run1
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run1
#qiime tools import \
--type EMPPairedEndSequences \
  --input-path data \
 --output-path DE_run1_seqs.qza
  
#import paired end reads for DE run2
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run2
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path data \
  --output-path DE_run2_seqs.qza
  
#import paired end reads for DE run2
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run3
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path data \
  --output-path DE_run3_seqs.qza
  
#demultiplex reads for DE Run1
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run1
qiime demux emp-paired  --i-seqs DE_run1_seqs.qza  --m-barcodes-file DE_ITS_Run1_Map.txt  --m-barcodes-column BarcodeSequence --o-per-sample-sequences DE_Run1_demux.qza   --o-error-correction-details demux-details_DE_Run1.qza   --p-no-golay-error-correction   --p-rev-comp-mapping-barcodes

#demultiplex reads for DE Run2
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run2
qiime demux emp-paired  --i-seqs DE_run2_seqs.qza  --m-barcodes-file DE_ITS_Run2_Map.txt  --m-barcodes-column BarcodeSequence   --o-per-sample-sequences DE_Run2_demux.qza   --o-error-correction-details demux-details_DE_Run2.qza   --p-no-golay-error-correction   --p-rev-comp-mapping-barcodes

#demultiplex reads for DE Run3
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run3
qiime demux emp-paired  --i-seqs DE_run3_seqs.qza  --m-barcodes-file DE_ITS_Run3_Map.txt  --m-barcodes-column BarcodeSequence   --o-per-sample-sequences DE_Run3_demux.qza   --o-error-correction-details demux-details_DE_Run3.qza   --p-no-golay-error-correction   --p-rev-comp-mapping-barcodes 
  
#export Run1 demux fastq 
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run1
qiime tools export --input-path DE_Run1_demux.qza --output-path DE_Run1_demux_fastq
 
#export Run2 demux fastq 
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run2
qiime tools export --input-path DE_Run2_demux.qza --output-path DE_Run2_demux_fastq
 
#export Run3 demux fastq 
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/DE_Run3
qiime tools export --input-path DE_Run3_demux.qza --output-path DE_Run3_demux_fastq
  
#move all fastq files into a single folder
cd /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS
mkdir DE_demux

#reimport fastq files to make a master seq of paired-end sequences for all DE samples
qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path DE_manifest.txt \
  --output-path DE_seqs_full.qza \
  --input-format PairedEndFastqManifestPhred33V2

#join paired end reads with vsearch
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs DE_seqs_full.qza \
  --o-merged-sequences DE_ITS_joined.qza 

#quality filter joined reads
qiime quality-filter q-score \
--i-demux  DE_ITS_joined.qza \
--o-filtered-sequences  DE_ITS_filt.qza \
--o-filter-stats  DE_ITS_filt_stats.qza \
--p-min-quality 20

#dereplicate sequences with vsearch
qiime vsearch dereplicate-sequences \
--i-sequences DE_ITS_filt.qza \
--o-dereplicated-table derep_table.qza \
--o-dereplicated-sequences derep_seqs.qza

#call OTUs at 97% with vsearch
 qiime vsearch cluster-features-de-novo \
  --i-sequences derep_seqs.qza \
  --i-table derep_table.qza \
  --p-perc-identity 0.97 \
  --o-clustered-table vsearch_otu_table.qza \
  --o-clustered-sequences vearch_rep_seqs.qza \
--p-threads 24

#process with DADA2
qiime dada2 denoise-paired \
 --i-demultiplexed-seqs DE_seqs_full.qza \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 150 \
  --p-trunc-len-r 150 \
  --o-table dada2_table.qza \
 --o-representative-sequences dada2_rep-seqs.qza \
 --o-denoising-stats dada2_denoising-stats.qza \
--p-n-threads 24 \
--p-n-reads-learn 24 \
--p-min-overlap 1
```

## Train UNITE v9 
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
qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads unite-ver9-seqs_99.qza \
--i-reference-taxonomy unite-ver9-taxonomy_99.qza \
--o-classifier unite-ver9-99-classifier.qza
```

## Assign taxonomy/make taxa plots
```
#Assign taxonomy with sklearn/UNITE v9
qiime feature-classifier classify-sklearn --i-classifier /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/unite-ver9-99-classifier.qza --p-n-jobs 24 --i-reads dada2_rep-seqs.qza --o-classification dada2_tax.qza

qiime feature-classifier classify-sklearn --i-classifier /hpcstor6/scratch01/p/patrick.kearns/Becker_lab_ITS/unite-ver9-99-classifier.qza --p-n-jobs 24 --i-reads vearch_rep_seqs.qza --o-classification vsearch_tax.qza

#make taxa barplots
qiime taxa barplot --o-visualization vsearch_taxa_plot.qzv --m-metadata-file DE_full_map.txt --i-table vsearch_otu_table.qza --i-taxonomy vsearch_tax.qza
qiime taxa barplot --o-visualization dada2_taxa_plot.qzv --m-metadata-file DE_full_map.txt --i-table dada2_table.qza --i-taxonomy dada2_tax.qza
```

## Export OTU tables to text files
```
qiime tools export --input-path  vsearch_otu_table.qza --output-path vsearch_otu_table
biom convert -i vsearch_otu_table/feature-table.biom -o vsearch_otu_table.txt --to-tsv

qiime tools export --input-path  dada2_table.qza --output-path dada2_otu_table
biom convert -i dada2_otu_table/feature-table.biom -o vsearch_otu_table.txt --to-tsv
```

## Export rep seqs to fasta file
```
qiime tools export --input-path dada2_rep-seqs.qza  --output-path dada2_rep_seqs
qiime tools export --input-path vearch_rep_seqs.qza  --output-path vsearch_rep_seqs

```

## Export taxa plots and taxonomy assignments to text files
```
qiime tools export --input-path dada2_tax.qza --output-path dada2_tax
qiime tools export --input-path vsearch_tax.qza --output-path vsearch_tax
```
