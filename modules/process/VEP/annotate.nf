


process ANNOT_MERGED_MSVCF {


    label 'VEP'

	tag "VEP annotate : Shard_${shard} -> $version"
	
	script:
		new_vcf_name = vcf_gz.getBaseName(2)


	input:
		tuple 	val (shard),
				val (version),
				path (vcf_gz)

	output:
		tuple 	val (shard),
				val (version),
				path ("${shard}/${new_vcf_name}.ANNOTATED.vcf.gz"), emit : ANNOTATED_msVCF_shard_Channel


		path ("${shard}/${new_vcf_name}.ANNOTATED.vcf.gz.tbi")


    script:
	"""
	mkdir -p ${shard}

	vep --cache  --offline  --format vcf  --vcf  --compress_output bgzip --fork ${task.cpus} --buffer_size 20000	--output_file ${shard}/${new_vcf_name}.ANNOTATED.vcf.gz   -i ${vcf_gz} \
		--assembly ${params.vep_BUILD}  	--dir_cache ${params.vep_cache_dir} 	--cache_version ${params.vep_VERSION}  --fasta ${params.fasta}  --verbose 	--species homo_sapiens 	--refseq --dont_skip \
		--everything 	--no_stats 		--overlaps	\
		--plugin LoF,loftee_path:${params.vep_Loftee_code},human_ancestor_fa:${params.vep_Loftee_data}/human_ancestor.fa.gz,gerp_bigwig:${params.vep_Loftee_data}/gerp_conservation_scores.homo_sapiens.GRCh38.bw,conservation_file:${params.vep_Loftee_data}/loftee.sql \
		--dir_plugins ${params.vep_Loftee_code} \
		--custom ${params.vep_Loftee_data}/gerp_conservation_scores.homo_sapiens.GRCh38.bw,GERP,bigwig \
		--custom ${params.vep_ClinVar},ClinVar,vcf,exact,0,AF_ESP,AF_EXAC,AF_TGP,ALLELEID,CLNDN,CLNDNINCL,CLNDISDB,CLNDISDBINCL,CLNHGVS,CLNREVSTAT,CLNSIG,CLNSIGCONF,CLNSIGINCL,CLNVC,CLNVCSO,CLNVI,DBVARID,GENEINFO,MC,ONCDN,ONCDNINCL,ONCDISDB,ONCDISDBINCL,ONC,ONCINCL,ONCREVSTAT,ONCCONF,ORIGIN,RS,SCIDN,SCIDNINCL,SCIDISDB,SCIDISDBINCL,SCIREVSTAT,SCI,SCIINCL \
		--custom ${params.vep_HGMD},HGMD,vcf,exact,0,CLASS,MUT,GENE,STRAND,DNA,PROT,DB,PHEN,RANKSCORE,SVTYPE,END,SVLEN \
		--custom ${params.vep_GNOMAD_GEN},gnomAD4g,vcf,exact,0,AC,AN,AF,grpmax,fafmax_faf95_max,fafmax_faf95_max_gen_anc,nhomalt,AC_grpmax,AF_grpmax,AN_grpmax,nhomalt_grpmax,faf95,faf99,fafmax_faf99_max,fafmax_faf99_max_gen_anc,lcr,non_par,segdup,cadd_phred,revel_max,spliceai_ds_max,pangolin_largest_ds,phylop,sift_max,polyphen_max 

	bcftools index --tbi ${shard}/${new_vcf_name}.ANNOTATED.vcf.gz

	if [ \"\$(zgrep -v ^# ${vcf_gz} | wc -l)\" -eq \"\$(zgrep -v ^# ${shard}/${new_vcf_name}.ANNOTATED.vcf.gz | wc -l)\" ]; then 
		echo 'Same line number verified : Match!'; 
	else 
		echo 'Error: not Same line number!'; 
		exit 1;
	fi

	"""
}




/*
AC,AN,AF,grpmax,fafmax_faf95_max,fafmax_faf95_max_gen_anc,nhomalt,AC_grpmax,AF_grpmax,AN_grpmax,nhomalt_grpmax,faf95,faf99,fafmax_faf99_max,fafmax_faf99_max_gen_anc,lcr,non_par,segdup,cadd_phred,revel_max,spliceai_ds_max,pangolin_largest_ds,phylop,sift_max,polyphen_max
*/

