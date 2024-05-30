

include { RUN_IGG_GLOBAL_CENSUS }			from '../modules/process/Dragen/step_2.nf' 


Fasta_Channel 				= Channel.fromPath(params.fasta				,checkIfExists:true).first()
Fasta_idx_Channel 			= Channel.fromPath(params.fasta_idx			,checkIfExists:true).first()


workflow DRAGEN_GG_STEP2 {

	main:

		Utils.testVersionFile(params.input_file, params, log);
		Census_Files_List = constructCensusesChannel(params.input_file)
		Census_Files_Channel = Channel.fromList(Census_Files_List)


		Census_Files_Channel
		.groupTuple()
		.set{Census_Files_GroupedbyShard_Channel}



		RUN_IGG_GLOBAL_CENSUS(
			Census_Files_GroupedbyShard_Channel,
			Fasta_Channel, 
			Fasta_idx_Channel,
			params.SHARD_SIZE,
			params.COHORT,
			params.this_input_name
		)


	emit:
		RUN_IGG_GLOBAL_CENSUS.out.Step2_Channel_Censues_batch_shard_Channel

}




def constructCensusesChannel(version_file){

	log.info "[INFO] Constructing Channel of Censuses Files"

	def census = []

			

	for(shard in params.SHARDS){

		def counter = 0
		new File(version_file).eachLine { line ->

			counter += 1

			def batch = line
			def this_cohort_name = params.COHORT

			if (params.meta){
				def a = line.split(',');

				if (a.size() != 2){
					log.error("[ERROR] Format error in line $counter : expected 2 columns (batch,cohort)");
					System.exit(1)
				}

				batch = a[0];
				this_cohort_name = a[1];
			}

			File census_file = new File(params.simple_cohorts_path+ '/' + this_cohort_name +'/BATCHES/'+'Batch_'+batch+'/Step1/'+shard+'/'+"${this_cohort_name}__Batch_${batch}__Shard${shard}.cns.gz")
			File census_idx_file = new File(params.simple_cohorts_path+ '/' + this_cohort_name +'/BATCHES/'+'Batch_'+batch+'/Step1/'+shard+'/'+"${this_cohort_name}__Batch_${batch}__Shard${shard}.cns.gz.tbi")
			if (!census_file.exists()){
				log.error("[ERROR]  ${census_file} : doesn't exist");
				System.exit(1) 
			}
			if (!census_idx_file.exists()){
				log.error("[ERROR]  ${census_idx_file} : doesn't exist");
				System.exit(1) 
			}
			census_shard_batch = [shard, file(census_file), file(census_idx_file)]
			census << census_shard_batch
		}
	}

	return census
}

