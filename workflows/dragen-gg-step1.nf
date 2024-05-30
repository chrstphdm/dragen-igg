
include { RUN_IGG_COHORT_CENSUS }			from '../modules/process/Dragen/step_1.nf' 


Fasta_Channel 				= Channel.fromPath(params.fasta				,checkIfExists:true).first()
Fasta_idx_Channel 			= Channel.fromPath(params.fasta_idx			,checkIfExists:true).first()


workflow DRAGEN_GG_STEP1 {


	SamplesList = testBatchFile(params.input_file);

	Channel
    .fromPath(params.input_file)
    .splitText()
    .set{GVCF_files_Channel}

	GVCF_files_Channel
	.map{it -> it.toString().trim()+".tbi"}
	.set{GVCF_idx_Channel}



	RUN_IGG_COHORT_CENSUS(
		SamplesList,
		GVCF_files_Channel.collect(),
		GVCF_idx_Channel.collect(), 
		Fasta_Channel, 
		Fasta_idx_Channel,
		params.SHARD_SIZE,
		params.SHARDS,
		params.COHORT,
		params.this_input_name
	)

}

def testBatchFile(batch_file){

	log.info "[INFO] Checking gVCF files & indexes in Batch File : ${batch_file}"


	def samples = []

	new File(batch_file).eachLine { sample ->
		File gvcf_file = new File(sample)
		if (!gvcf_file.exists()){
			log.error("[ERROR]  ${gvcf_file} : doesn't exist");
			System.exit(1) 
		}
		File gvcf_file_idx = new File(sample+'.tbi')
		if (!gvcf_file_idx.exists()){
			log.error("[ERROR]  ${gvcf_file_idx} : doesn't exist");
			System.exit(1) 
		}

		samples << gvcf_file.getName()
	}

	return samples

}