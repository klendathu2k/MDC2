class: CommandLineTool
cwlVersion: v1.0
baseCommand: ["sh", "init-env.sh"]

requirements:
  InitialWorkDirRequirement:  
    listing:
      - entryname: init-env.sh
        entry: |-
          export SPHENIX_BUILD="$(inputs.build)"
          echo `hostname`
          source /opt/sphenix/core/bin/sphenix_setup.sh $SPHENIX_BUILD
          echo $SPHENIX_BUILD

inputs:
  build: string

outputs:
  example_out:
    type: stdout

stdout: output.txt

