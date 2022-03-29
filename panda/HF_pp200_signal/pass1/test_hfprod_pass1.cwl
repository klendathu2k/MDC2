class: CommandLineTool
cwlVersion: v1.0
baseCommand: ["sh", "init-env.sh"]

requirements:
  InitialWorkDirRequirement:  
    listing:

      - entryname: init-env.sh
        entry: |-
          export USER="$(id -u -n)"
          export LOGNAME=${USER}
          export HOME=/sphenix/u/${USER}
          export SHREK_BUILD="$(inputs.build)"
          export SHREK_NEVENTS="$(inputs.nevents)"
          export SHREK_TYPE="$(inputs.type)"
          export SHREK_OUTFILE="$(inputs.outfile)"
          export SHREK_OUTDIR="$(inputs.outdir)"
          export SHREK_RUNNUM="$(inputs.runnumber)"
          if [ -z $1 ]
             then
                export SHREK_SEQNUM=00001
             else
                export SHREK_SEQNUM=$1
          fi	
          echo "Initialize sPHENIX Production Environment `hostname`"
          echo =============================================================
          source /opt/sphenix/core/bin/sphenix_setup.sh $SHREK_BUILD
          echo build      = $SHREK_BUILD
          echo nevents    = $SHREK_NEVENTS
          echo type       = $SHREK_TYPE
          echo outfile    = $SHREK_OUTFILE
          echo outdir     = $SHREK_OUTDIR
          echo run number = $SHREK_RUNNUM
          echo sequence   = $SHREK_SEQNUM

          echo Staging files:
          echo =============================================================
          echo $(inputs.stagecmd)
          $(inputs.stagecmd)

          ls -la



inputs:
  build: string
  nevents: int
  type: string
  outfile: string
  outdir: string
  runnumber: int
  stagecmd: string
       
outputs:
  example_out:
    type: stdout

stdout: output.txt

