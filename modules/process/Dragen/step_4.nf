




process RUN_MERGE_MSVCF {
    
    label 'DRAGEN_SW'

    tag "STEP 4 : $cohort_name -> Shard_${shard} -> $version"



    input:
    tuple val (shard),
          val (version),
          val (original_cohort),
          val (batchs),
          path (msvcfs),
          path (msvcf_idxs)

    val (shard_file_name)

    val (ordered_batches)
		path Fasta
		path Fasta_idx
    val  shards_size
    val  cohort_name


    output:
    tuple val (shard),
          val (version),
          path ("${shard}/${cohort_name}__${version}__Shard${shard}.vcf.gz"), emit : Step4_msVCF_shard_Channel


          path ("${shard}/${cohort_name}__${version}__Shard${shard}.vcf.gz.tbi")

    script:

    def shard_Map = [:]
  

    for (s in shard_file_name) {
        if (s[0]==shard){
          key = s[1].toString() + s[2].toString()
          shard_Map[key] = s[3]
        }
    }

    def ordered_msVCF = []
    for (b in ordered_batches) {
        key = b[1]+b[0]
        msVCF_filename = shard_Map.get(key)
        msVCF_filename_f = file(msVCF_filename).getName()
        ordered_msVCF << msVCF_filename_f
    }


    """
    echo ${ordered_msVCF.join(",")} | tr ',' '\\n' | sed  "s|^|\$PWD/|" > INPUT_LIST_FILE

    mkdir -p ${shard}

    ${params.dragen_bin_path} \
      --sw-mode \
      --num-threads ${task.cpus} \
      --enable-gvcf-genotyper-iterative true \
      --merge-batches true \
      --shard $shard/${shards_size} \
      --input-batch-list INPUT_LIST_FILE \
      --gg-enable-indexing=true \
      --logging-to-output-dir true \
      --output-directory=${shard} \
      --output-file-prefix=${cohort_name}__${version}__Shard${shard} \
      --ht-reference ${Fasta} \
      --gg-remove-nonref=${params.REMOVE_NON_REF} \
      --gg-max-subregion-size ${params.MAX_SUBREGION_SIZE} \
      --gg-concurrency-region-size ${params.CONCURRENCY_REGION_SIZE}


	"""

}


