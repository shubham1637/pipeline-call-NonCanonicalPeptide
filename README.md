
# call-NonCanonicalPeptides
- [call-NonCanonicalPeptides](#call-noncanonicalpeptides)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Entrypoints](#entrypoints)
  - [Input CSV](#input-csv)
    - [Entrypoint: 'parser'](#entrypoint-parser)
    - [Entrypoint: 'gvf' or 'fasta'](#entrypoint-gvf-or-fasta)
  - [Config](#config)
    - [Tool specific namespaces](#tool-specific-namespaces)
      - [parseREDItools](#parsereditools)
      - [parseSTARFusion](#parsestarfusion)
      - [parseArriba](#parsearriba)
      - [parseFusionCatcher](#parsefusioncatcher)
      - [parseCIRCexplorer](#parsecircexplorer)
      - [callVariant](#callvariant)
      - [filterFasta](#filterfasta)
      - [splitFasta](#splitfasta)
      - [summarizeFasta](#summarizefasta)
      - [decoyFasta](#decoyfasta)
  - [Outputs](#outputs)
  - [License](#license)
## Overview

This pipeline takes genomic and transcriptomic variation data such as SNP, INDEL, and Fusion, and calls variant peptides from them using the graph-based algorithm [moPepGen](https://github.com/uclahs-cds/package-moPepGen)

---

## How To Run

1. Create sample-specifc config file using the [template](config/template.config)

2. Create a sample-specific input CSV file using [this](inputs/input-gvf.csv) template when using GVF or variant FASTA as entrypoint or [this](inputs/input-parsers.csv) template when using raw variant files.

3. To run on UCSL-CDS' Azure clusters, see the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit it. For general usage, launch with the command below:

```
nextflow run path/to/pipeline-call-NoncanonicalPeptide/main.nf -c sample.config
```

> :warning: This pipeline should only run one sample at a time. The input CSV file should only contain one sample and all mutation files associated with the one sample.

> :information_source: The pipeline requires the genomic reference index generated by the `moPepGen generateIndex` command. See [here](https://uclahs-cds.github.io/package-moPepGen/generate-index/) for the usage of this command.

---

## Flow Diagram

![flow-chart](img/diagram.drawio.svg?raw=true)

## Entrypoints

This pipeline has three entrypoints, 'parser', 'gvf', and 'fasta'. When using the 'parser' entrypoint, the raw files from variant callers are expected and corresponding moPepGen parsers are called before running `callVariant`. When using the 'gvf' entrypoint, the moPepGen GVF files are expected and moPepGen `callVariant` is called directly on them. When using the 'fasta' entrypoint, not only the moPepGen GVF files are expected from the `input_csv`, but also variant peptide FASTA file needs to be input to the pipeline. It then skips `callVariant` and only the downstream `filterFasta`, `splitFasta`, `encodeFasta` and `summarizeFasta` are called.

---

## Input CSV

### Entrypoint: 'parser'

The fields required for the input CSV files are listed below. See example [here](inputs/input-parsers.csv).

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| software | yes | The software used to call this variant. Must come from VEP, STAR-Fusion, rMATS, CIRCexplorer, and REDItools. |
| alt_splic_type | no | Alternative splicing type. Required for rMATS. Must come from SE, A5SS, A3SS, MXE, and RI. |
| source | yes | Source of the variant. For example, gSNP, sSNV, Fusion, circRNA, etc |
| path | yes | Path to the variant file. |

### Entrypoint: 'gvf' or 'fasta'

Directly input of GVF files is also supported, which will skip all `moPepGen` parsers. In this case, the input CSV should contain only one column being the path to the GVF files. See [here](inputs/input-gvf.csv) for example.

---

## Config

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `input_csv` | yes | Path to the input CSV file See [Input CSV](#input-csv). |
| `output_dir` | yes | Output directory. |
| `sample_id` | yes | Sample ID. |
| `index_dir` | yes | Path the the genome index directory, generated by `moPepGen generateIndex`. See [here](https://uclahs-cds.github.io/package-moPepGen/generate-index/) for the detail of this command. |
| `ucla_cds` | no | Whether to use UCLA-CDS' cluster specific configuration. Defaults to `true`. |
| `save_intermediate_files` | no | Whether to save intermediate files. Defaults to `false`. |
| `entrypoint` | no | When set to `parser`, it expects to receive raw variant files. When set to `gvf`, it expects to receive GVF files that are already parsed by moPepGen's parsers. |
| `variant_peptide` | no | Path to the variant peptide FASTA file. Only need when using 'fasta' entrypoint. |
| `novel_orf_peptide` | no | Noncoding peptide database generated by moPepGen `callNovelORF`, to be split together (default: None) |
| `alt_translation_peptide` | no | Alternative translation peptide database generated by moPepGen `callAltTranslation`, to be split together (default: None) |
| `enable_filter_fasta` | no | Whether to run `filterFasta` on the variant, noncoding, and/or the merged FASTA file. Defaults to `false`. If `true` is given, corresponding namespaces must be specified under `params.enable_filter_fasta` according to `database_processing_modes`. |
| `exprs_table` | no | Gene expression table used to filter variant peptide FASTA. Required when `enable_filter_fasta` is `true`. |
| `database_processing_modes` | yes | Database postprocessing modes. Must be at least one of 'merge', 'split' and 'plain'. For 'merge', noncoding and variant peptides are merged into one database FASTA. For 'split', noncoding and variant peptides are split into separate database files. For 'plain', the FASTA file output by moPepGen is first filtered (if specified) and then encoded and decoyed. Filter (if specifed), encode and decoy database are done in the same way as 'plain' for 'merge' and 'split'. |
| `process_unfiltered_fasta` | no | Whether the unfiltered fasta files should be processed (filtering, encode and decoy). Defaults to `true` unless using FASTA entrypoint or `enable_filter_fasta` is `false`. |
| `enable_encode_fasta` | no | Whether to run `encodeFasta` on the variant peptide FASTA called by `callVariant` （runs once after `filterFasta` and `splitFasta`, if used). Defaults to `false`. |
| `enable_decoy_fasta` | no | Whether to run `decoyFasta` on the variant peptide FASTA called by `callVariant` (runs once after `filterFasta`, `splitFasta` and `encodeFasta`, if used). Defaults to `false`. |

### Tool specific namespaces

The variables below are set under tool specific namespaces. See [this](test/test-integration-entrypoint-parser/test.config) example config to see how they are set. If the tool is not used, the namespace does not needs to be set. For example, if REDItools results is not included in the input CSV, `moPepGen parseREDItools` won't be called, so the `parseREDItools` namespace does not need to be present in the config file.

#### parseREDItools

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `transcript_id_column` | no | The column index for transcript ID. If your REDItools table doesnot contains it, use the `AnnotateTable.py` from the REDItoolspackage. (default: 16) |
| `min_coverage_alt` | no | Minimal read coverage of alterations to be parsed. (default: 3) |
| `min_frequency_alt` | no | Minimal frequency of alteration to be parsed. (default: 0.1) |
| `min_coverage_dna` | no | Minimal read coverage at the alteration site of WGS. Set it to -1 to skip checking this. (default: 10) |

#### parseSTARFusion

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `min_est_j` | no | Minimal estimated junction reads to be included. (default: 5.0) |

#### parseArriba

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `min_split_read1` | no | Minimal `split_read1` value. (default: 1) |
| `min_split_read2` | no | Minimal `split_read2` value. (default: 1) |
| `min_confidence` | no | Minimal confidence value. (default: medium) |

#### parseFusionCatcher

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `max_common_mapping` | no | Maximal number of common mapping reads. (default: 0) |
| `min_spanning_unique` | no | Minimal spanning unique reads. (default: 5) |

#### parseCIRCexplorer

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `min_read_number` | no | Minimal number of junction read counts. (default: 1) |
| `min_fpb_circ` | no | Minimal CRICscore value for CIRCexplorer3. Recommends to 1, defaults to None (default: None) |
| `min_circ_score` | no | Minimal CIRCscore value for CIRCexplorer3. Recommends to 1, defaults to None (default: None) |
| `intron_start_range` | no | The range of difference allowed between the intron start and the reference position. (default: -2,0) |
| `intron_end_range` | no | The range of difference allowed between the intron end and the reference position. (default: -100,5) |

#### callVariant

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `max_variants_per_node` | no | Maximal number of variants per node. This argument can be useful when there are local regions that are heavily mutated. When creating the cleavage graph, nodes containing variants larger than this value are skipped. Set to -1 to avoid this check. When multiple values are specified, they will be used as retry stretagy. (default: [7]) |
| `additional_variants_per_misc` | no | Additional variants allowed for every miscleavage. This argument is used together with --max-variants-per-node to handle hypermutated regions. Set to -1 to avoid this check. When multiple values are specified, they will be used as retry stretagy. (default: [2]) |
| `max_adjacent_as_mnv` | no | Max number of adjacent variants that should be merged. (default: 2) |
| `min_nodes_to_collapse` | no | When making the cleavage graph, the minimal number of nodes to trigger pop collapse. (default: 30) |
| `naa_to_collapse` | no | The number of bases used for pop collapse. (default: 5) |
| `selenocysteine-termination` | no | Include peptides of selenoproteins where the UGA is treated as termination instead of Sec. |
| `w2f_reassignment` | no | Include peptides with W > F (Tryptophan to Phenylalanine) reassignment. |
| `cleavage_rule` | no | Enzymatic cleavage rule. (default: trypsin) |
| `miscleavage` | no | Number of cleavages to allow per non-canonical peptide. (default: 2) |
| `min_mw` | no | The minimal molecular weight of the non-canonical peptides. (default: 500.0) |
| `min_length` | no | The minimal length of non-canonical peptides, inclusive. (default: 7) |
| `max_length` | no | The maximum length of non-canonical peptides, inclusive. (default: 25) |
| `timeout_seconds` | no | Time out in seconds for each transcript. (default: 1800) |

#### filterFasta

Filter fasta can run separately for variant, noncoding, and alternative translation peptide FASTA, so this section can take up to four namespaces, named `variant_peptide`, `novel_orf_peptide` and `alt_translation_peptide`. The parameters allowed in each namespace are listed below. You can set `quant_cutoff` for variant peptides as 200 and for noncoding peptides as 100. If either namespace is not defined, the corresponding filter won't run.

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `skip_lines` | no | Number of lines to skip when reading the expression table.Defaults to 0 (default: 0) |
| `delimiter` | no | Delimiter of the expression table. Defaults to tab. (default: '\t') |
| `tx_id_col` | yes | The index for transcript ID in the RNAseq quantification results. Index is 1-based. (default: None) |
| `quant_col` | yes | The column index number for quantification. Index is 1-based. (default: None) |
| `quant_cutoff` | yes | Quantification cutoff. (default: None) |
| `keep_all_coding` | no | Keep all coding genes, regardless of their expression level. (default: false) |
| `keep_all_noncoding` | no | Keep all noncoding genes, regardless of their expression level. (default: false) |

#### splitFasta

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `order_source` | no | Order of sources, separate by comma. E.g., SNP,SNV,Fusion (default: None) |
| `group_source` | no | Group sources. E.g., PointMutation:gSNP,sSNV INDEL:gINDEL,sINDEL (default: None) |
| `max_source_groups` | no | Maximal number of different source groups to be separate intoindividual database FASTA files. Defaults to 1 (default: 1) |
| `additional_split` | no | For peptides that were not already split into FASTAs up tomax_source_groups, those involving the following source will be splitinto additional FASTAs with decreasing priority (default: None) |

#### summarizeFasta

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `order_source` | no | Order of sources, separate by comma. E.g., SNP,SNV,Fusion (default: None) |
| `cleavage_rule` | no | Enzymatic cleavage rule. (default: trypsin) |
| `invalid_protein_as_noncoding` | no | Treat any transcript that the protein sequence is invalid (contains the * symbol) as noncoding. (default: False) |

#### decoyFasta

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `decoy_string` | no | The decoy string that is combined with the FASTA header for decoy sequences. `str` Default: `DECOY_` |
| `decoy_string_position` | no | Should the decoy string be placed at the start or end of FASTA headers? `str` Default: 'prefix', Choices: ['prefix', 'suffix'] |
| `method` | no | Method to be used to generate the decoy sequences from target sequences. `str`. Default: 'reverse'. Choices: ['reverse', 'shuffle'] |
| `non_shuffle_pattern` | no | Residues to not shuffle and keep at the original position. Separate by common (e.g. "K,R") str |
| `shuffle_max_attempts` | no | Maximal attempts to shuffle a sequence to avoid any identical decoy sequence. `int` Default: 30 |
| `seed` | no | Random seed number. `int` |
| `order` | no | Order of target and decoy sequences to write in the output FASTA. `str` Default: 'juxtaposed'. Choices: ['juxtaposed', 'target_first', 'decoy_first'] |
| `keep_peptide_nterm` | Whether to keep the peptide N terminus constant. `str`. Default: 'true' Choices: ['true', 'false'] |
| `keep_peptide_cterm` | no | Whether to keep the peptide C terminus constant. `str` Default: 'true'. Choices: ['true', 'false'] |

---

## Outputs

 Output and Output Parameter/Flag | Description |
| ------------ | ------------------------ |
| <sample_id>_<source>_<software>.gvf | Intermediate GVF files. |
| <sample_id>_variant_peptides.fasta | The complete variant peptide FASTA file. |
| split/<sample_id>_<source>.fasta | Split database FASTA files can be used for multi-step library search and FDR calculation. |
| encode/<sample_id>_<source>.{fasta,fasta.dict} | Encoded database FASTA files with header being replaced with UUID. |
| decoy/<sample_id>_<source>.{fasta,fasta.dict} | Decoy database FASTA files with either reversed or shuffled sequences. |

---

## License

Author: Chenghao Zhu (ChenghaoZhu@mednet.ucla.edu)

pipeline-call-NoncanonicalPeptide is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

pipeline-call-NoncanonicalPeptide is a nextflow pipeline to call non-canonical peptides as custom databases for proteogenomic analysis.

Copyright (C) 2022 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
