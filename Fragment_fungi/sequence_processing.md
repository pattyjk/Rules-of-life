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
  --o-merged-sequences RoL_ITS_joined.qza \
--p-min-quality 30
 
#quality filter joined reads
qiime quality-filter q-score \
--i-demux  RoL_ITS_joined.qza \
--o-filtered-sequences  RoL_ITS_filt.qza \
--o-filter-stats  RoL_ITS_filt_stats.qza 

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

#assign taxonomy

#export OTU tables to text files
