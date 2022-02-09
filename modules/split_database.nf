/* module for splitting database */
include { generate_args } from "${moduleDir}/common"

ARGS = [
    'order_source': '--order-source',
    'group_source': '--group-source',
    'max_source_groups': '--max-source-groups',
    'additional_split': '--additional-split'
]

FLAGS = [
    'invalid-protein-as-noncoding': '--invalid-protein-as-noncoding'
]

def get_args_and_flags() {
    return [ARGS, FLAGS]
}

process split_database {

    container params.docker_image_moPepGen

    publishDir params.final_output_dir,
        mode: 'copy',
        pattern: "split"

    publishDir "${params.process_log_dir}/${task.process.replace(':', '/')}-${task.index}/",
        mode: 'copy',
        pattern: '.command.*',
        saveAs: { "log${file(it).name}" }

    input:
        file gvfs
        file variant_fasta
        file noncoding_fasta
        file index_dir

    output:
        file output_dir
        file ".command.*"

    script:
    output_dir = 'split'
    output_prefix = "${output_dir}/${params.sample_name}"
    noncoding_arg = noncoding_fasta.name == '_NO_FILE' ? '' : "--noncoding-peptides ${noncoding_fasta}"
    extra_args = generate_args(params, 'splitDatabase', ARGS, FLAGS)
    """
    set -euo pipefail

    moPepGen splitDatabase \
        --gvf ${gvfs} \
        --variant-peptides ${variant_fasta} \
        ${noncoding_arg} \
        ${extra_args} \
        --index-dir ${index_dir} \
        --output-prefix ${output_prefix} \
    """
}