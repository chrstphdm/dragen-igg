




process RUN_IGG_COHORT_CENSUS {
    
    label 'DRAGEN_SW'

	tag "STEP 1 : $cohort_name -> $batch_name -> shard $shard/$shards_size"




    input:
		val SamplesList
		path GVCF_files
		path GVCF_idx
		path Fasta
		path Fasta_idx
		val  (shards_size)
		each (shard)
        val cohort_name
		val batch_name



    output:
		path ("${shard}")//, emit: Step1_Channel


    script:

    """
	echo ${SamplesList.join(",")} | tr ',' '\\n' | sed  "s|^|\$PWD/|" > INPUT_LIST_FILE

	mkdir ${shard}

	${params.dragen_bin_path} \
    --sw-mode \
	--num-threads ${task.cpus} \
    --enable-gvcf-genotyper-iterative true \
    --gvcfs-to-cohort-census true \
    --variant-list INPUT_LIST_FILE \
    --shard $shard/$shards_size \
    --logging-to-output-dir true \
    --output-directory=${shard} \
	--output-file-prefix=${cohort_name}__${batch_name}__Shard${shard} \
    --ht-reference ${Fasta} \
	--gg-remove-nonref=${params.REMOVE_NON_REF} \
	--gg-max-subregion-size ${params.MAX_SUBREGION_SIZE} \
	--gg-concurrency-region-size ${params.CONCURRENCY_REGION_SIZE} 

	"""

}


