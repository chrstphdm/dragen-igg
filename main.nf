
nextflow.enable.dsl = 2


include { DRAGEN_GG_STEP1 } from './workflows/dragen-gg-step1'

include { DRAGEN_GG_STEP2 } from './workflows/dragen-gg-step2'

include { DRAGEN_GG_STEP3 } from './workflows/dragen-gg-step3'



Utils.checkRequirements(params.input_file, params.step, log);
Utils.initExecution(params.this_step_dir, workflow, params, log);



workflow {


	switch(params.step) { 
		case 1: 
			DRAGEN_GG_STEP1 () 
			break;
		case 2: 
			DRAGEN_GG_STEP2 () 
			DRAGEN_GG_STEP3 (DRAGEN_GG_STEP2.out)
			break;
		default:
			log.error "ERROR: Step params MUST be [1|2];"
			exit 1
	} 

	
}


workflow.onComplete = {

	if (workflow.success){
		Utils.terminateExecution(params.this_step_dir, 'DONE', workflow, log);
	}
	
}


workflow.onError = {
	Utils.terminateExecution(params.this_step_dir, 'FAILED', workflow, log);
}


