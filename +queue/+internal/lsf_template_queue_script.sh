#!/usr/bin/env zsh

# Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

#BSUB -J ###JOBNAME######TASKS###
#BSUB -o ###TMPDIR###/###JOBNAME###.o%J.%I
#BSUB -M ###ARCHREQUIREMENTS###
#BSUB -W ###TIME###

module load MISC
module load matlab

matlabfunction="queue.internal.wrapper_function"

job_name="'###JOBNAME###'"
tmpdir="'###TMPDIR###'"

matlabparam="###MATLABPARAM###"

matlabcommand="###DEFAULTMATLABCOMMAND###"

echo `date`: This job is running on ${HOST} which is a $OSTYPE system
$matlabcommand $matlabparam "$matlabfunction(${LSB_JOBINDEX},$job_name,$tmpdir,'$TMP');exit"
