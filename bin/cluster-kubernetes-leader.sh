#!/bin/bash -x
#	./bin/cluster-kubernetes-leader.sh
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
test -n "$debug"                || exit ${EX_USAGE}			;
test -n "$HostedZoneName"       || exit ${EX_USAGE}			;
test -n "$RecordSetNameKube"    || exit ${EX_USAGE}			;
test -n "$log"                  || exit ${EX_USAGE}			;
#########################################################################
calico=https://docs.projectcalico.org/v3.14/manifests			;
cidr=192.168.0.0/16							;
ip=10.168.1.100                                                         ;
kube=$RecordSetNameKube.$HostedZoneName                                 ;
kubeconfig=/etc/kubernetes/admin.conf 					;
#########################################################################
while true								;
do									\
        systemctl							\
		is-enabled						\
			kubelet                               		\
	|								\
		grep enabled                                          	\
		&& break						\
                                                                        ;
done									;	
#########################################################################
echo $ip $kube | tee --append /etc/hosts                           	;
kubeadm init								\
	--upload-certs							\
	--control-plane-endpoint					\
		"$kube"							\
	--pod-network-cidr						\
		$cidr							\
	--ignore-preflight-errors					\
		all							\
	2>&1								\
	|								\
		tee --append $log					\
									;
#########################################################################
kubectl apply								\
	--filename							\
		$calico/calico.yaml					\
	--kubeconfig							\
                $kubeconfig						\
	2>&1								\
	|								\
		tee --append $log					\
									;
#########################################################################
userID=1001								;
USER=ssm-user								;
HOME=/home/$USER							;
mkdir -p $HOME/.kube							;
cp /etc/kubernetes/admin.conf $HOME/.kube/config			;
chown -R $userID:$userID $HOME						;
echo									\
	'source <(kubectl completion bash)'				\
	|								\
		tee --append $HOME/.bashrc				\
									;
#########################################################################
