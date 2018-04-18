#cloud-config
# vim: syntax=yaml

package_upgrade: true

write_files:
  - path: /etc/systemd/system/docker.service.d/10-storage-driver.conf
    owner: root:root
    permissions: 0644
    content: |
      [Service]
      ExecStart=
      ExecStart=/usr/bin/dockerd -H fd:// --storage-driver=overlay

  - path: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    owner: root:root
    permissions: 0644
    content: |
      [Service]
      Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
      Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
      Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
      Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
      Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
      Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
      Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
      Environment="KUBELET_EXTRA_ARGS=--cloud-provider=aws"
      ExecStart=
      ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS



packages:
  - apt-transport-https
  - ca-certificates
  - gnupg2
  - awscli

runcmd:
  - aws ec2 modify-instance-attribute --no-source-dest-check --region us-east-2 --instance-id $(curl -sL http://169.254.169.254/latest/meta-data/instance-id)
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys 0xF76221572C52609D 0x3746C208A7317B0F
  - echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
  - echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  - apt-get update && apt-get install -y --allow-unauthenticated docker-engine kubelet kubeadm kubectl kubernetes-cni
  - systemctl daemon-reload
  - systemctl enable docker
  - systemctl enable kubelet
  - echo 127.0.0.1 $(curl 169.254.169.254/latest/meta-data/hostname) | sudo tee -a /etc/hosts
  - curl 169.254.169.254/latest/meta-data/hostname | sudo tee /etc/hostname
  - sudo hostname $(curl 169.254.169.254/latest/meta-data/hostname)
  - systemctl start docker
  - sleep 120 && for i in $(seq 10); do echo "kubeadm join $i" && kubeadm join --token=${k8s_token} --discovery-token-unsafe-skip-ca-verification ${control_plane_ip}:6443 && break || sleep 15; done

output: { all : '| tee -a /var/log/cloud-init-output.log' }

final_message: "The system is finally up, after $UPTIME seconds"