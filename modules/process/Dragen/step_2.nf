




process RUN_IGG_GLOBAL_CENSUS {
    
    label 'DRAGEN_SW'

    tag "STEP 2 : shard $shard"




    input:
		tuple val (shard) , path(Censuses), path(Censuses_idx)
		path Fasta
		path Fasta_idx
		val  (shards_size)
    val  (cohort_name)
		val  (version_name)


    output:
		path ("${shard}")//, emit: Step2_Channel
    tuple val (shard),
          val (version_name),
          path ("${shard}/${cohort_name}__${version_name}__Shard${shard}.cns.gz"),
          path ("${shard}/${cohort_name}__${version_name}__Shard${shard}.cns.gz.tbi"), emit : Step2_Channel_Censues_batch_shard_Channel


    script:

    """
    echo $Censuses | tr ' ' '\\n' | sed  "s|^|\$PWD/|" > INPUT_LIST_FILE
    mkdir ${shard}

    ${params.dragen_bin_path} \
      --sw-mode \
      --num-threads ${task.cpus} \
      --enable-gvcf-genotyper-iterative true \
      --aggregate-censuses true \
      --shard $shard/${shards_size} \
      --variant-list INPUT_LIST_FILE \
      --logging-to-output-dir true \
      --output-directory=${shard} \
      --output-file-prefix=${cohort_name}__${version_name}__Shard${shard} \
      --ht-reference ${Fasta} \
      --gg-remove-nonref=${params.REMOVE_NON_REF} \
      --gg-max-subregion-size ${params.MAX_SUBREGION_SIZE} \
      --gg-concurrency-region-size ${params.CONCURRENCY_REGION_SIZE}

	"""

}


