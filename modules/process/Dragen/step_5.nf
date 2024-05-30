




process RUN_CONCAT_MSVCF {
    
    label 'BCFTOOLS'

    tag "STEP 5 : $cohort_name -> $version"




    input:
      tuple val (shard),
            val (version),
            path (msvcfs)

      val (shard_file_name)

      path Fasta
      path Fasta_idx
      val  shards_size
      val  cohort_name
      val  is_annotated




    script:
      PREFIX = ''
      if (is_annotated == 'TRUE'){
            PREFIX = '.ANNOTATED'
      }

    def shard_Map = [:]

     for (s in shard_file_name) {
          shard_Map[s[0]] = s[1]
    }

    def ordered_msVCF = []
    for (b in params.SHARDS) {
        msVCF_filename = shard_Map.get(b)
        msVCF_filename_f = file(msVCF_filename).getName()
        ordered_msVCF << msVCF_filename_f
    }


      """
      echo ${ordered_msVCF.join(",")} | tr ',' '\\n' > INPUT_LIST_FILE
      
      bcftools concat \\
      --file-list  INPUT_LIST_FILE \\
      --naive \\
      -Oz \\
      --threads ${task.cpus} \\
      --output "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz"

      bcftools index --tbi --threads ${task.cpus} \\
      --output "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz.tbi"   \\
      "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz"

      md5sum "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz"     > "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz.md5sum"
      md5sum "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz.tbi" > "${params.this_iteration_dir}/msVCF_Global/${cohort_name}__${version}${PREFIX}.Agg.vcf.gz.tbi.md5sum"


      """

}


