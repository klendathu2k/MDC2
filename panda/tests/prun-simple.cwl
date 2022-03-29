#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

#
# CWL wrapper to panda prun
#

baseCommand: [ "echo", "prun" ]

inputs:
  number_of_jobs:
    type: int
    inputBinding:
      position: 1
      prefix: --nJobs