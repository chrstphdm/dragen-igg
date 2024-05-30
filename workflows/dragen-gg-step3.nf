

include { RUN_IGG_MSVCF }			from '../modules/process/Dragen/step_3.nf'

include { RUN_MERGE_MSVCF }			from '../modules/process/Dragen/step_4.nf' 

include { ANNOT_MERGED_MSVCF }		from '../modules/process/VEP/annotate.nf'

include { RUN_CONCAT_MSVCF }		from '../modules/process/Dragen/step_5.nf'
											
include { RUN_CONCAT_MSVCF as RUN_CONCAT_ANNOT_MSVCF}		from '../modules/process/Dragen/step_5.nf'

											


Fasta_Channel 				= Channel.fromPath(params.fasta				,checkIfExists:true).first()
Fasta_idx_Channel 			= Channel.fromPath(params.fasta_idx			,checkIfExists:true).first()


workflow DRAGEN_GG_STEP3 {

	take:
		Global_Census_Files_Channel
		//[shard, params.this_input_name, file(gCensus_file), file(gCensus_idx_file)]

	main:

		Utils.testVersionFile(params.input_file, params, log);

		Cohorts_Files_List = constructCohortsChannel(params.input_file)
		Cohorts_Files_Channel = Channel.fromList(Cohorts_Files_List)


		// Global_Census_Files_List = constructGlobalCensusChannel()
		// Global_Census_Files_Channel = Channel.fromList(Global_Census_Files_List)



		Global_Census_Files_Channel
		.cross(Cohorts_Files_Channel)
		.map { it -> tuple (it[0][0], it[0][1],it[0][2],it[0][3], it[1][0], it[1][1],it[1][2],it[1][3],it[1][4],it[1][5],it[1][6])}
		.set{Global_Census_Cohort_Files_Channel}


		RUN_IGG_MSVCF(
			Global_Census_Cohort_Files_Channel,
			Fasta_Channel,
			Fasta_idx_Channel,
			params.SHARD_SIZE,
			params.COHORT
		)


		ordered_batches = getBatchesOrder(params.input_file)
		
		

		RUN_MERGE_MSVCF(
			RUN_IGG_MSVCF.out.Step3_msVCF_batch_shard_Channel.groupTuple(by:[0,1]),
			RUN_IGG_MSVCF.out.Step3_msVCF_batch_shard_Channel.map{it -> tuple(it[0], it[2],it[3],it[4])}.toList(),
			ordered_batches,
			Fasta_Channel,
			Fasta_idx_Channel,
			params.SHARD_SIZE,
			params.COHORT
		)



		RUN_CONCAT_MSVCF(
			RUN_MERGE_MSVCF.out.Step4_msVCF_shard_Channel.groupTuple(by:1),
			RUN_MERGE_MSVCF.out.Step4_msVCF_shard_Channel.map{it -> tuple(it[0], it[2])}.toList(),
			Fasta_Channel,
			Fasta_idx_Channel,
			params.SHARD_SIZE,
			params.COHORT,
			'FALSE'
		)
	

		if (params.do_annot){
			ANNOT_MERGED_MSVCF(
				RUN_MERGE_MSVCF.out.Step4_msVCF_shard_Channel
			)

			RUN_CONCAT_ANNOT_MSVCF(
				ANNOT_MERGED_MSVCF.out.ANNOTATED_msVCF_shard_Channel.groupTuple(by:1),
				ANNOT_MERGED_MSVCF.out.ANNOTATED_msVCF_shard_Channel.map{it -> tuple(it[0], it[2])}.toList(),
				Fasta_Channel,
				Fasta_idx_Channel,
				params.SHARD_SIZE,
				params.COHORT,
				'TRUE'
			)
		}

}



def constructCohortsChannel(version_file){

	log.info "[INFO] Constructing Channel of Cohorts Files"

	def cohorts = []

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


			File cohort_file = new File(params.simple_cohorts_path+ '/' + this_cohort_name +'/BATCHES/'+'Batch_'+batch+'/Step1/'+shard+'/'+"${this_cohort_name}__Batch_${batch}__Shard${shard}.cht.gz")
			File cohort_idx_file = new File(params.simple_cohorts_path+ '/' + this_cohort_name +'/BATCHES/'+'Batch_'+batch+'/Step1/'+shard+'/'+"${this_cohort_name}__Batch_${batch}__Shard${shard}.cht.gz.tbi")
			if (!cohort_file.exists()){
				log.error("[ERROR]  ${cohort_file} : doesn't exist");
				System.exit(1) 
			}
			if (!cohort_idx_file.exists()){
				log.error("[ERROR]  ${cohort_idx_file} : doesn't exist");
				System.exit(1) 
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

			cohort_shard_batch = [shard, this_cohort_name, batch, file(cohort_file), file(cohort_idx_file), file(census_file), file(census_idx_file)]
			cohorts << cohort_shard_batch
		}
	}
	return cohorts
}


// def constructGlobalCensusChannel(){

// 	log.info "[INFO] Constructing Global Census Files"

// 	def gCensus = []

// 	for(shard in params.SHARDS){
// 		File gCensus_file = new File(params.this_iteration_dir+'/Step2/'+shard+'/'+"${params.COHORT}__${params.this_input_name}__Shard${shard}.cns.gz")
// 		File gCensus_idx_file = new File(params.this_iteration_dir+'/Step2/'+shard+'/'+"${params.COHORT}__${params.this_input_name}__Shard${shard}.cns.gz.tbi")
// 		if (!gCensus_file.exists()){
// 			log.error("[ERROR]  ${gCensus_file} : doesn't exist");
// 			System.exit(1) 
// 		}
// 		if (!gCensus_idx_file.exists()){
// 			log.error("[ERROR]  ${gCensus_idx_file} : doesn't exist");
// 			System.exit(1) 
// 		}
// 		gCensus_shard = [shard, params.this_input_name, file(gCensus_file), file(gCensus_idx_file)]
// 		gCensus << gCensus_shard
// 	}

// 	return gCensus
// }





def getBatchesOrder(version_file){

	log.info "[INFO] Getting batches order from version file : ${version_file}"


	def batches_ordered = []

	def counter = 0 

	new File(version_file).eachLine { line ->

		counter += 0
		
		def batch = line;
		def this_cohort_name = params.COHORT;

		if (params.meta){

			def a = line.split(',');

			if (a.size() != 2){
				log.error("[ERROR] Format error in line $counter : expected 2 columns (batch,cohort)");
				System.exit(1)
			}

			batch = a[0];
			this_cohort_name = a[1];
		}
			
		batches_ordered << [batch,this_cohort_name] 

	}




	return batches_ordered

}