cwlVersion: v1.0
class: Workflow

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
                export SHREK_SEQNUM=01234
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

          date


inputs:
  build: string
  nevents: int
  type: string
  outfile: string
  outdir: string
  runnumber: int
  stagecmd: string

outputs:
  outDS:
    type: string
    outputSource: make_signal/outDS

steps:
  make_signal:
    run: prun
    in:
      opt_exec:
        default: "touch output.txt; date >> output.txt; ls >> output.txt ; init-env.sh %RNDM:00001 >> output.txt; cat output.txt > /sphenix/user/sphnxpro/out.txt"
      opt_args:
        default: "--outputs output.txt --site BNL_OSG_SPHENIX"
    out: [outDS]

