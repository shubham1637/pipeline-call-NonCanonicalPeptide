include { merge_fasta } from './merge_fasta'
include { filter_fasta as filter_fasta_merged } from './filter_fasta'
include { encode_fasta } from './encode_fasta'
include { decoy_fasta } from './decoy_fasta'
include { summarize_fasta as summarize_fasta_merge } from './summarize_fasta'

/**
* Workflow to process the database FASTA file(s) with variant and noncoding peptides merged.
*/

workflow process_database_merge {
    take:
    gvf_files
    variant_fasta

    main:
    merge_fasta(variant_fasta.mix(Channel.fromPath(params.noncoding_peptides)))

    if (params.filter_fasta_merged) {
        filter_fasta_merged(
            merge_fasta.out[0],
            file(params.exprs_table),
            file(params.index_dir),
            'merged_peptides'
        )
        merged_fasta_filtered = filter_fasta_merged.out[0]
        summarize_fasta_merge(
            gvf_files,
            merged_fasta_filtered,
            file('_NO_FILE'),
            file(params.index_dir)
        )
    } else {
        merged_fasta_filtered = merge_fasta.out[0]
    }

    if (params.encode_fasta) {
        encode_fasta(merged_fasta_filtered)
        encoded_fasta_file = encode_fasta.out[0]
    } else {
        encoded_fasta_file = merged_fasta_filtered
    }

    if (params.decoy_fasta) {
        decoy_fasta(encoded_fasta_file)
    }
}