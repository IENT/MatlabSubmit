#!/bin/tcsh

# Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

set matlabfunction="queue.internal.wrapper_function"

set job_name="'###JOBNAME###'"
set tmpdir="'###TMPDIR###'"
#$ -cwd
#$ -N ###JOBNAME###
#$ -t ###TASKS###
#$ -P ###PROJECTNAME###
#$ -q ###LISTOFSERVERS###
#$ -p ###PRIORITY###
#$ -o ###TMPDIR###
#$ -l ###ARCHREQUIREMENTS###

set matlabparam="###MATLABPARAM###"

switch ($OSTYPE)
	case darwin:
		set matlabcommand="###MATLABCOMMANDDARWIN###"
		breaksw
	default:
		set matlabcommand="###DEFAULTMATLABCOMMAND###"
		breaksw
endsw

echo `date`: This job is running on ${HOST} which is a $OSTYPE system
$matlabcommand $matlabparam "$matlabfunction(${SGE_TASK_ID},$job_name,$tmpdir,'$TMP');exit"
