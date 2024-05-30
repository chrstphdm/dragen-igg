import groovy.json.JsonOutput

class Utils {

	public static void testVersionFile(version_file, params, log){

		log.info "[INFO] Checking Batch Censuses Files in : ${version_file}"

		if (params.meta){
			log.info "[INFO] Mode Meta Cohort detected !"
		}else{
			log.info "[INFO] Mode Simple Cohort detected !"
		}

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
			
			
			File batch_step1_flag = new File(params.simple_cohorts_path+ '/' + this_cohort_name +'/BATCHES/'+'Batch_'+batch+'/Step1/trace/DONE')
			log.debug "Testing batch ${batch}"
			log.debug "Testing batch status :  ${params.simple_cohorts_path}/${this_cohort_name}/BATCHES/Batch_${batch}/Step1/trace/DONE"
			if (!batch_step1_flag.exists()){
				log.error("[ERROR] ${batch_step1_flag} : doesn't exist");
				log.error("  --> Cohort :  ${this_cohort_name}");
				log.error("  --> Batch :  ${batch}");
				System.exit(1)
			}else{
				log.debug "Exists !"
			}

		}

		if (counter <= 1){
			log.error("[ERROR] Expecting 2 or more Batches to merge : found $counter");
			System.exit(1)
		}else{
			log.debug "Version File contain ${counter} batches"
		}

		

	}




	public static void initExecution(stepDir, workflow, params, log) {

		log.info "[INFO] Output Dir : ${stepDir}"

		File f = new File("${stepDir}/trace");
		if (! f.mkdirs()) {
			log.error("ERROR: Cannot initialize the BATCH output dir properly : [${f}]\n(cannot create. Already exists ?)");
			System.exit(1) 
		}


		File config_flag  = new File("${stepDir}/trace/CONFIG")


		if ( ! config_flag.createNewFile()){
			log.error("ERROR: Cannot initialize the BATCH output dir properly : [${config_flag}]\n(exists already ?)");
			System.exit(1) 
		}else{
			config_flag.append("userName: ${workflow.userName}\n")
			config_flag.append("start: ${workflow.start}\n")
			config_flag.append("launchDir: ${workflow.launchDir}\n")
			config_flag.append("workDir: ${workflow.workDir}\n")
			config_flag.append("commandLine: ${workflow.commandLine}\n")
			config_flag.append("scriptFile: ${workflow.scriptFile}\n")
			config_flag.append("projectDir: ${workflow.projectDir}\n")
			config_flag.append("configFiles: ${workflow.configFiles}\n")
		}

		File params_flag  = new File("${stepDir}/trace/params.json")


		if ( ! params_flag.createNewFile()){
			log.error("ERROR: Cannot initialize the BATCH output dir properly : [${params_flag}]\n(exists already ?)");
			System.exit(1) 
		}else{
			def pretty = JsonOutput.prettyPrint(JsonOutput.toJson(params))
			params_flag.append("params: ${pretty}\n")

		}

	}



	// close BATCHE output Dir
	public static void terminateExecution(stepDir,flag, workflow, log) {

		def nxf_log_file = System.getenv('NXF_LOG_FILE')
		def src = new File(nxf_log_file)
		def dst = new File("${stepDir}/trace/LOG")


		// COPY LOG FILE

		try {
			dst << src.text
		}
		catch(Exception e) {
			log.warn ("Cannot copy log file:\nFrom\n$src\nto\n$dst")
		}

		// CREATE STATUS FILE
		File flag_file = new File("${stepDir}/trace/${flag}")

		if ( ! flag_file.createNewFile()){
			log.warn "Cannot close the BATCH output dir properly : ${flag_file}"
		}

	}


	public static void checkRequirements(input_f, step, log) {

		log.info "Checking requirements..."
		log.debug "Checking input file:"
		File input_file = new File(input_f)
		String input_file_name = input_file.getName()
		log.debug "Input fileName: $input_file_name"

		log.debug "User gave step: ${step}"

		
		if (!input_file.exists()){
			log.error("[ERROR]  ${input_file} : doesn't exist");
			System.exit(1) 
		}
		switch(step) { 
			case 1:
				if (input_file_name ==~ /Batch_\d+\.gvcfs\.list/){
					log.debug "Input file Name matches regex"
				}else{
					log.error("[ERROR]  ${input_file_name} : doesn't match format Batch_{\\d}.gvcfs.list");
					System.exit(1) 
				}
				break;
			case 2:
				if (input_file_name ==~ /Version_\d+\.batches\.list/){
					log.debug "Input file Name matches regex"
				}else{
					log.error("[ERROR]  ${input_file_name} : doesn't match format Version_{\\d}.batches.list");
					System.exit(1) 
				}
				break;
			default:
				log.error("Unknown STEP : ${step}");
				System.exit(1)  
		} 


	}





}