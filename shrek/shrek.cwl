cwlVersion: v1.0
class: Workflow
 
requirements:

  InitialWorkDirRequirement:  
    listing:

      - entryname: runjob.sh
        entry: |-
          # Pass off to the jobname script
          shift
          source $(inputs.jobname)-env.sh $@ 

      - entryname: $(inputs.jobname)-env.sh
        entry: |-

          export $(inputs.jobname)_build="$(inputs.build)"
          export $(inputs.jobname)_nevents="$(inputs.nevents)"
          export $(inputs.jobname)_njobs="$(inputs.njobs)"
          export $(inputs.jobname)_nfilesperjob="$(inputs.nfilesperjob)"
          export $(inputs.jobname)_type="$(inputs.type)"
          export $(inputs.jobname)_outfile="$(inputs.outfile)"
          export $(inputs.jobname)_outdir="$(inputs.outdir)"
          export $(inputs.jobname)_logdir="$(inputs.logdir)"
          export $(inputs.jobname)_runnum="$(inputs.runnumber)"
          if [ -z $1 ]
             then
                export $(inputs.jobname)_seqnum=00001
             else
                export $(inputs.jobname)_seqnum=$1
          fi	
          echo "Initialize sPHENIX Production Environment `hostname` `date`"
          echo =============================================================
          source /opt/sphenix/core/bin/sphenix_setup.sh $$(inputs.jobname)_build
          echo build      = $$(inputs.jobname)_build
          echo nevents    = $$(inputs.jobname)_nevents
          echo type       = $$(inputs.jobname)_type
          echo outfile    = $$(inputs.jobname)_outfile
          echo outdir     = $$(inputs.jobname)_outdir
          echo run number = $$(inputs.jobname)_runnum
          echo sequence   = $$(inputs.jobname)_seqnum
          echo
          echo Staging files:
          echo =============================================================
          echo $(inputs.stagecmd)
          $(inputs.stagecmd)
          echo
          echo Directory listing
          echo =============================================================
          ls

          echo Dumping the driver scripts
          echo =============================================================
          cat runjob.sh
          cat $(inputs.jobname)-env.sh
          echo
          echo =============================================================
          echo =============================================================
          echo =============================================================
          echo
          echo Running user commands:
          echo =============================================================
          $(inputs.commands) 
         

inputs:
  build:                string
  nevents:              int?
  njobs:                int?
  nfilesperjob:         int?
  type:                 string
  outfile:              string
  outdir:               string
  runnumber:            int
  stagecmd:             string?
  commands:             string
  extra_panda_args:     string

outputs:
  outDS:
    type: string
    outputSource: make_signal/outDS

steps:
  make_signal:
    run: prun
    in:
      opt_exec:
        default: "ls -la > out.txt; cat *.py >> out.txt; cat *.h >> out.txt; echo $(runtime.outdir); ls $(runtime.outdir); echo $(runtime.tmpdir); ls $(runtime.tmpdir); echo `pwd` >> out.txt; cat out.txt > /sphenix/user/sphnxpro/out.txt"
      opt_args:
        default: "--outputs output.txt --site BNL_OSG_SPHENIX --nJobs 1 --bexec 'ls' "
    out: [outDS]

