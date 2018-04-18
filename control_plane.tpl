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

  - path: /etc/kubernetes/kubeadm.conf
    owner: root:root
    permissions: 0644
    content: |
      apiVersion: kubeadm.k8s.io/v1alpha1
      kind: MasterConfiguration
      networking:
        podSubnet: 192.168.0.0/16
      cloudProvider: aws
      token: ee99fa.4fd6d8638c0e21bd
      tokenTTL: "0"
      apiServerCertSANs: [${elb_dnsname}]
      featureGates:
        CoreDNS: true
        DynamicKubeletConfig: true
      apiServerExtraArgs:
        admission-control: NamespaceAutoProvision,Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota,PodTolerationRestriction
        cloud-provider: aws
        audit-log-path: "/var/log/kube-audit"
        audit-log-maxage: "10"
        audit-log-maxsize: "100"
        audit-policy-file: "/etc/kubernetes/audit/audit-policy.yaml"
        oidc-issuer-url: https://jpw.auth0.com/
        oidc-client-id: 80I4BFW2KNa9mJb5MQaacMU3IiF4HCd1
        oidc-username-claim: email
        oidc-groups-claim: groups

      apiServerExtraVolumes: 
        - name: "audit-policy"
          hostPath: "/etc/kubernetes/audit"
          mountPath: "/etc/kubernetes/audit"

  - path: /etc/kubernetes/audit/audit-policy.yaml
    owner: root:root
    permissions: 0644
    content: |
      apiVersion: audit.k8s.io/v1beta1 # This is required.
      kind: Policy     
      # Don't generate audit events for all requests in RequestReceived stage.
      omitStages:
        - "RequestReceived"
      rules:
      # The following requests were manually identified as high-volume and low-risk,
      # so drop them.
      - level: None
        users: ["system:kube-proxy"]
        verbs: ["watch"]
        resources:
          - group: "" # core
            resources: ["endpoints", "services"]
      - level: None
        users: ["system:unsecured"]
        namespaces: ["kube-system"]
        verbs: ["get"]
        resources:
          - group: "" # core
            resources: ["configmaps"]
      - level: None
        users: ["kubelet"] # legacy kubelet identity
        verbs: ["get"]
        resources:
          - group: "" # core
            resources: ["nodes"]
      - level: None
        userGroups: ["system:nodes"]
        verbs: ["get"]
        resources:
          - group: "" # core
            resources: ["nodes"]
      - level: None
        users:
          - system:kube-controller-manager
          - system:kube-scheduler
          - system:serviceaccount:kube-system:endpoint-controller
        verbs: ["get", "update"]
        namespaces: ["kube-system"]
        resources:
          - group: "" # core
            resources: ["endpoints"]
      - level: None
        users: ["system:apiserver"]
        verbs: ["get"]
        resources:
          - group: "" # core
            resources: ["namespaces"]
      # Don't log these read-only URLs.
      - level: None
        nonResourceURLs:
          - /healthz*
          - /version
          - /swagger*
      # Don't log events requests.
      - level: None
        resources:
          - group: "" # core
            resources: ["events"]
      # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,
      # so only log at the Metadata level.
      - level: Metadata
        resources:
          - group: "" # core
            resources: ["secrets", "configmaps"]
          - group: authentication.k8s.io
            resources: ["tokenreviews"]
      # Get repsonses can be large; skip them.
      - level: Request
        verbs: ["get", "list", "watch"]
        resources:
          - group: "" # core
          - group: "admissionregistration.k8s.io"
          - group: "apps"
          - group: "authentication.k8s.io"
          - group: "authorization.k8s.io"
          - group: "autoscaling"
          - group: "batch"
          - group: "certificates.k8s.io"
          - group: "extensions"
          - group: "networking.k8s.io"
          - group: "policy"
          - group: "rbac.authorization.k8s.io"
          - group: "settings.k8s.io"
          - group: "storage.k8s.io"
      # Default level for known APIs
      - level: RequestResponse
        resources:
          - group: "" # core
          - group: "admissionregistration.k8s.io"
          - group: "apps"
          - group: "authentication.k8s.io"
          - group: "authorization.k8s.io"
          - group: "autoscaling"
          - group: "batch"
          - group: "certificates.k8s.io"
          - group: "extensions"
          - group: "networking.k8s.io"
          - group: "policy"
          - group: "rbac.authorization.k8s.io"
          - group: "settings.k8s.io"
          - group: "storage.k8s.io"
      # Default level for all other requests.
      - level: Metadata


packages:
  - build-essential
  - curl
  - gnupg2
  - htop
  - git-core
  - apt-transport-https
  - ca-certificates
  - vim-nox
  - tmux
  - rsync
  - keychain
  - awscli

runcmd:
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys 0xF76221572C52609D 0x3746C208A7317B0F
  - echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
  - echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  - apt-get update && apt-get install -y --allow-unauthenticated docker-engine kubelet kubeadm kubectl kubernetes-cni
  - systemctl daemon-reload
  - systemctl enable docker
  - systemctl enable kubelet
  - systemctl start docker
  - echo 127.0.0.1 $(curl 169.254.169.254/latest/meta-data/hostname) | sudo tee -a /etc/hosts
  - curl 169.254.169.254/latest/meta-data/hostname | sudo tee /etc/hostname
  - sudo hostname $(curl 169.254.169.254/latest/meta-data/hostname)
  - kubeadm init --config /etc/kubernetes/kubeadm.conf
  - mkdir -p $HOME/.kube
  - sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  - sudo chown $(id -u):$(id -g) $HOME/.kube/config
  - kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

output: { all : '| tee -a /var/log/cloud-init-output.log' }

final_message: "The system is finally up, after $UPTIME seconds"