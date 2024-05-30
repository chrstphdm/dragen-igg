




process RUN_IGG_MSVCF {
    
    label 'DRAGEN_SW'

    tag "STEP 3 : $cohort_name -> ${original_cohort}_Batch_${batch} -> $version -> shard $shard/$shards_size"


    publishDir  params.this_iteration_dir+'/'+params.step_label,
                mode: params.publish_dir_mode,
                pattern: "${original_cohort}_Batch_*",
                saveAs: { "${shard}/$it" }




    input:
    tuple val(shard), val(version), path(gCensus_file), path(gCensus_idx_file), val(shard_bis), val(original_cohort) , val(batch), path(batch_file), path(batch_idx_file), path(batch_cns_file), path(batch_cns_idx_file)
		path Fasta
		path Fasta_idx
    val  shards_size
    val  (cohort_name)


    output:
		path ("${original_cohort}_Batch_${batch}")//, emit: Step3_Channel
    tuple val (shard),
          val (version),
          val (original_cohort),
          val (batch),
          path ("${original_cohort}_Batch_${batch}/${original_cohort}__Batch_${batch}__${version}__Shard${shard}.vcf.gz"),
          path ("${original_cohort}_Batch_${batch}/${original_cohort}__Batch_${batch}__${version}__Shard${shard}.vcf.gz.tbi"), emit : Step3_msVCF_batch_shard_Channel


    script:

    """
    mkdir -p ${original_cohort}_Batch_${batch}

    ${params.dragen_bin_path} \
      --sw-mode \
      --num-threads ${task.cpus} \
      --enable-gvcf-genotyper-iterative true \
      --generate-msvcf true \
      --shard $shard/${shards_size} \
      --input-cohort-file $batch_file \
      --input-census-file $batch_cns_file \
      --input-global-census-file $gCensus_file \
      --logging-to-output-dir true \
      --output-directory=${original_cohort}_Batch_${batch} \
      --output-file-prefix=${original_cohort}__Batch_${batch}__${version}__Shard${shard} \
      --ht-reference ${Fasta} \
      --gg-remove-nonref=${params.REMOVE_NON_REF} \
      --gg-max-subregion-size ${params.MAX_SUBREGION_SIZE} \
      --gg-concurrency-region-size ${params.CONCURRENCY_REGION_SIZE}


	"""

}


