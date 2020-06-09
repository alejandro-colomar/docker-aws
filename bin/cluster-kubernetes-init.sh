#!/bin/bash -x
#	./bin/cluster-kubernetes-init.sh
################################################################################
##       Copyright (C) 2020        Sebastian Francisco Colomar Bauza          ##
##       Copyright (C) 2020        Alejandro Colomar Andrés                   ##
##       SPDX-License-Identifier:  GPL-2.0-only                               ##
################################################################################


################################################################################
##	source								      ##
################################################################################
source	lib/libalx/sh/sysexits.sh


#########################################################################
set +x && test "$debug" = true && set -x				;
#########################################################################
test -n "$A"			|| exit ${EX_USAGE}			;
test -n "$debug"		|| exit ${EX_USAGE}			;
test -n "$domain"		|| exit ${EX_USAGE}			;
test -n "$HostedZoneName"	|| exit ${EX_USAGE}			;
test -n "$RecordSetNameKube"	|| exit ${EX_USAGE}			;
test -n "$stack"		|| exit ${EX_USAGE}			;
#########################################################################
export=" 								\
  export debug=$debug 							\
"									;
log=/root/kubernetes-install.log                              		;
path=$A/bin								;
sleep=10								;
#########################################################################
export=" 								\
  $export								\
  && 									\
  export A=$A								\
  && 									\
  export domain=$domain							\
"									;
file=cluster-kubernetes-install.sh					;
targets="								\
	InstanceManager1						\
	InstanceManager2						\
	InstanceManager3						\
	InstanceWorker1							\
	InstanceWorker2							\
	InstanceWorker3							\
"									;
send_remote_file $domain "$export" $file $path $sleep $stack "$targets"	;
#########################################################################
export=" 								\
  $export								\
  && 									\
  export HostedZoneName=$HostedZoneName					\
  && 									\
  export log=$log							\
  && 									\
  export RecordSetNameKube=$RecordSetNameKube				\
"									;
file=cluster-kubernetes-leader.sh					;
targets="								\
	InstanceManager1						\
"									;
send_remote_file $domain "$export" $file $path $sleep $stack "$targets"	;
#########################################################################
file=cluster-kubernetes-wait.sh						;
send_remote_file $domain "$export" $file $path $sleep $stack "$targets"	;
#########################################################################
command="								\
	grep --max-count 1						\
		certificate-key						\
		$log							\
"									;
token_certificate=$(							\
  encode_string "							\
    $(									\
      send_wait_targets "$command" $sleep $stack "$targets"		\
    )									\
  "									;	
)									;
#########################################################################
command="								\
	grep --max-count 1						\
		discovery-token-ca-cert-hash				\
		$log							\
"									;
token_discovery=$(							\
  encode_string "							\
    $(									\
      send_wait_targets "$command" $sleep $stack "$targets"		\
    )									\
  "									;	
)									;
#########################################################################
command="								\
	grep --max-count 1						\
		kubeadm.*join						\
		$log							\
"									;
token_token=$(								\
  encode_string "							\
    $(									\
      send_wait_targets "$command" $sleep $stack "$targets"		\
    )									\
  "									;	
)									;
#########################################################################
export=" 								\
  $export								\
  &&									\
  export token_certificate=$token_certificate				\
  &&									\
  export token_discovery=$token_discovery				\
  &&									\
  export token_token=$token_token					\
"									;
file=cluster-kubernetes-manager.sh					;
targets="								\
	InstanceManager2						\
	InstanceManager3						\
"									;
send_remote_file $domain "$export" $file $path $sleep $stack "$targets"	;
#########################################################################
unset token_certificate							;
#########################################################################
export=" 								\
  $export								\
"									;
file=cluster-kubernetes-worker.sh					;
targets="								\
	InstanceWorker1							\
	InstanceWorker2							\
	InstanceWorker3							\
"									;
send_remote_file $domain "$export" $file $path $sleep $stack "$targets"	;
#########################################################################
