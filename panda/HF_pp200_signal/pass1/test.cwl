cwlVersion: v1.0
class: Workflow

requirements:
  MultipleInputFeatureRequirement: {}

inputs:
  signal: string
  background: string

outputs:
  outDS:
    type: string
    outputSource: combine/outDS
  

steps:
  make_signal:
    run: prun
    in:
      opt_inDS: signal
      opt_containerImage:
        default: docker://busybox
      opt_exec:
        default: "echo %IN > abc.dat; echo 123 > def.zip"
      opt_args:
        default: "--outputs abc.dat,def.zip --nFilesPerJob 5"
    out: [outDS]