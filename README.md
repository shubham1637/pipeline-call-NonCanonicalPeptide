# call-NonCanonicalPeptides

- [call-NonCanonicalPeptides](#call-noncanonicalpeptides)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Input CSV](#input-csv)
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
      - [decoyFasta](#decoyfasta)
  - [Outputs](#outputs)
  - [License](#license)
## Overview

This pipeline takes genomic and transcriptomic variation data such as SNP, INDEL, and Fusion, and call variant peptides from them using the graph-based algorithm [moPepGen](https://github.com/uclahs-cds/private-moPepGen)

---

## How To Run

1. Create sample specifc config file using the [template](config/template.config)

2. Create a sample specific input CSV file using [this](inputs/input-gvf.csv) template when using GVF as entrypoint or [this](inputs/input-parsers.csv) template when using raw variant files.

3. To run on UCSL-CDS' Azure clusters, see the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit it. For general usage, launch with the comamnd below:

```
nextflow run path/to/pipeline-call-NoncanonicalPeptide/main.nf -c sample.config
```

> :warning: This pipeline should only run one sample at a time. The input CSV file should only contain one sample and all mutation files associated with the one sample.

> :information_source: The pipeline requires the genomic reference index generated by the `moPepGen generateIndex` command. See [here](https://uclahs-cds.github.io/private-moPepGen/generate-index/) for the usage of this command.

---

## Flow Diagram

![flow-chart](img/diagram.drawio.svg?raw=true)

---

## Input CSV

The input CSV file must contain the fields listed below. See example [here](inputs/input-parsers.csv)

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| software | yes | The software used to call this variant. Must come from VEP, STAR-Fusion, rMATS, CIRCexplorer, and REDItools. |
| alt_splic_type | no | Alternative splicing type. Required for rMATS. Must come from SE, A5SS, A3SS, MXE, and RI. |
| source | yes | Source of the variant. For example, gSNP, sSNV, Fusion, circRNA, etc |
| path | yes | Path to the variant file. |

Directly input of GVF files are also supported, which will skip all `moPepGen` parsers. In this case, the input CSV should contain only one column being the path to the GVF files. See [here](inputs/input-gvf.csv) for example.

---

## Config

| Field name | Required | Description |
| ---------- | -------- | ----------- |
| `input_csv` | yes | Path to the input CSV file See [Input CSV](#input-csv). |
| `output_dir` | yes | Output directory. |
| `sample_name` | yes | Sample name. |
| `index_dir` | yes | Path the the genome index directory, generated by `moPepGen generateIndex`. See [here](https://uclahs-cds.github.io/private-moPepGen/generate-index/) for the detail of this command. |
| `ucla_cds` | no | Whether to use UCLA-CDS' cluster specific configuration. Defaults to `true`. |
| `save_intermediate_files` | no | Whether to save intermediate files. Defaults to `false`. |
| `entrypoint` | no | When set to `parser`, it expects to receive raw variant files. When set to `gvf`, it expects to receive GVF files that are already parsed by moPepGen's parsers. |
| `filter_fasta` | no | Whether to run `filterFasta` on the variant peptide FASTA called by `callVariant`. Defaults to `false`. |
| `split_fasta` | no | Whether to run `splitFasta` on the variant peptide FASTA called by `callVariant`. Defaults to `false`. |
| `exprs_table` | no | Gene expression table used to filter variant peptide FASTA. Required when `filter_fasta` is `true`. |
| `noncoding_peptides` | no | Noncoding peptide database generated by moPepGen `callNoncoding`, to be split together (default: None) |

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
| `max_variants_per_node` | no | Maximal number of variants per node. This argument can be useful when there are local regions that are heavily mutated. When creating the cleavage graph, nodes containing variants larger than this value are skipped. Setting to -1 will avoid checking for this. (default: 7) |
| `cleavage_rule` | no | Enzymatic cleavage rule. (default: trypsin) |
| `miscleavage` | no | Number of cleavages to allow per non-canonical peptide. (default: 2) |
| `min_mw` | no | The minimal molecular weight of the non-canonical peptides. (default: 500.0) |
| `min_length` | no | The minimal length of non-canonical peptides, inclusive. (default: 7) |
| `max_length` | no | The maximum length of non-canonical peptides, inclusive. (default: 25) |

#### filterFasta

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
| <sample_name>_<source>_<software>.gvf | Intermediate GVF files. |
| <sample_name>_variant_peptides.fasta | The complete variant peptide FASTA file. |
| split/<sample_name>_<source>.fasta | Split database FASTA files can be used for multi-step library search and FDR calculation. |
| encode/<sample_name>_<source>.{fasta,fasta.dict} | Encoded database FASTA files with header being replaced with UUID. |
| decoy/<sample_name>_<source>.{fasta,fasta.dict} | Decoy database FASTA files with either reversed or shuffled sequences. |

---

## License

Author: Chenghao Zhu (ChenghaoZhu@mednet.ucla.edu)

pipeline-call-NoncanonicalPeptide is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

pipeline-call-NoncanonicalPeptide is a nextflow pipeline to call non-canonical peptides as custom databases for proteogenomic analysis.

Copyright (C) 2022 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
