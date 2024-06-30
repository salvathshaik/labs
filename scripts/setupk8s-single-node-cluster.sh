#!/bin/bash

prepare_node() {

   #### Install Kubernetes latest components
    which docker
    if [ $? -eq 0 ];then
       echo "docker is already installed no action required.."
       sudo systemctl restart docker.service
    else
       echo "docker is not installed.. continue to install"
       #wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installDocker.sh -P /tmp
       #sudo bash /tmp/installDocker.sh
       ##sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installDocker.sh -P /tmp
       sudo wget https://raw.githubusercontent.com/salwad-basha-shaik/labs/master/scripts/installDocker.sh -P /tmp
       sudo chmod 755 /tmp/installDocker.sh
       sudo bash /tmp/installDocker.sh
       sudo systemctl restart docker.service
       sudo systemctl enable docker.service
       sudo systemctl status docker.service
    fi 
    which cri-dockerd
    if [ $? -eq 0 ];then
       echo "docker is already installed no action required.."
       sudo systemctl restart cri-docker.service
    else
       echo "docker is not installed.. continue to install"
       #wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installCRIDockerd.sh -P /tmp
       #sudo bash /tmp/installCRIDockerd.sh
       #sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installCRIDockerd.sh -P /tmp
       sudo wget https://raw.githubusercontent.com/salwad-basha-shaik/labs/master/scripts/installCRIDockerd.sh -P /tmp
       sudo chmod 755 /tmp/installCRIDockerd.sh
       sudo bash /tmp/installCRIDockerd.sh
       sudo systemctl restart cri-docker.service
       sudo systemctl enable cri-docker.service
       sudo systemctl status cri-docker.service
    fi
    which kubelet
    if [ $? -eq 0 ];then
       echo "kubernetes modules are already installed no action required.."
    else
       echo "kuberenetes modules are not installed.. continue to install"
       #sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installK8S.sh -P /tmp
       #sudo bash /tmp/installK8S.sh
       ## Install kubeadm,kubelet,kubectl
       #sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installK8S.sh -P /tmp
       sudo wget https://raw.githubusercontent.com/salwad-basha-shaik/labs/master/scripts/installK8S.sh -P /tmp
       sudo chmod 755 /tmp/installK8S.sh
       sudo bash /tmp/installK8S.sh
    fi
  
}
create_cluster() {

    sudo kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock --ignore-preflight-errors=all
    if [ $? -eq 0 ];then
       echo "kuberenetes master initilized successfully"

       sudo mkdir -p $HOME/.kube
       sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
       sudo chown $(id -u):$(id -g) $HOME/.kube/config

       if [ -f $HOME/.kube/config ];then

            #kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml
            sudo wget https://docs.projectcalico.org/manifests/calico.yaml -P /tmp
            sudo sed -i 's|docker.io/calico|quay.io/calico|g' /tmp/calico.yaml
            kubectl apply -f /tmp/calico.yaml
            mnodename=`kubectl get nodes | grep control-plane | awk '{print $1}'`
            kubectl taint node $mnodename node-role.kubernetes.io/control-plane:NoSchedule-

       else
          echo "config file missing under user home.."
       fi
    else
       echo "kubeadm init is failed pleae check..."
    fi
     

}

################ MAIN ###################

if [ -f /etc/os-release ];then
   #osname=`hostnamectl | grep "Operating System" | cut -d' ' -f3`
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
   if [ $osname == "ubuntu" ];then
       prepare_node
       create_cluster
   elif [ $osname == "amzn" ];then
       prepare_node
       create_cluster
   elif [ $osname == "centos" ];then
       prepare_node
       create_cluster
   elif [ $osname == "ol" ];then
       prepare_node
       create_cluster
  fi
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi
exit 0
