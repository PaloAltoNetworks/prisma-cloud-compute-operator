# Resource specification

## Notes
- If `toolBundleUrl` is not specified, the tool bundle URL is built using `version`.
- If `consoleConfig.imageName` is not specified, the image name is built using `version` and `credentials.accessToken`.

## ConsoleDefender
- **apiVersion**: pcc.paloaltonetworks.com/v1alpha1
- **kind**: ConsoleDefender
- **metadata** ([ObjectMeta](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/object-meta/#ObjectMeta))  
Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
- **spec** ([ConsoleDefenderSpec](#ConsoleDefenderSpec))

## ConsoleDefenderSpec
- **namespace** (string), required  
Namespace in which the Console and Defenders will be deployed.
This should be the same namespace as the operator itself.
Default is twistlock.
- **orchestrator** (string), required  
Orchestrator being used. Must be kubernetes or openshift.
- **toolBundleUrl** (string), recommended  
URL of the tool bundle containing twistcli, the tool used to generate Prisma Cloud Compute YAML files.
Can either be an [isolated upgrade](https://docs.twistlock.com/docs/government/isolated_upgrades/isolated_upgrades.html) tarball or a release tarball URL.
- **version** (string), required  
Version of Prisma Cloud Compute to install.
- **credentials** (PrismaCloudComputeCredentials)  
Sensitive data to be used during installation.
Be aware that these credentials will be visible in the custom resource spec.
Only use this section if you cannot use secrets for whatever reason.
  - **credentials.accessToken** (string), required  
  32-character lowercase access token included in the license bundle.
  - **credentials.license** (string), required  
  Product license included in the license bundle.
  - **credentials.password** (string), required  
  Password to be used for the initial local administrator user.
  It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install.
  Default is change_me_after_install.
  - **credentials.username** (string), required  
  Username to be used for the initial local administrator user.
  Default is admin.
- **consoleConfig** (PrismaCloudComputeConsoleConfig)  
Options for installing Console.
They are ultimately passed to `twistcli` for YAML generation.
  - **consoleConfig.imagePullSecret** (string)  
  Secret needed to pull the Console image when using a private registry.
  - **consoleConfig.imageName** (string)  
  Console image to deploy.
  If no value is specified, the image is pulled from the Prisma Cloud Compute registry.
  - **consoleConfig.nodeLabels** (string)  
  Label to use as a nodeSelector for Console.
  Specify a label and value (e.g. "kubernetes.io/hostname=node-name").
  - **consoleConfig.persistentVolumeLabels** (string)  
  Label to match the PVC to the PV.
  - **consoleConfig.persistentVolumeStorage** (string)  
  Storage size of the PV.
  Default is 100Gi.
  - **consoleConfig.runAsUser** (string)  
  Run Console as UID 2674 (requires manual pre-configuration of ownership and permissions of the PV).
  Must be true or false.
  - **consoleConfig.serviceType** (string)  
  Service type for exposing Console. Supported values are ClusterIP, NodePort, and LoadBalancer.
  Default is ClusterIP.
  - **consoleConfig.storageClass** (string)  
  StorageClass to use when dynamically provisioning a PV for Console.
  A PV is dynamically provisioned if twistcli cannot find the PV specified with the Persistent Volume Label option.
  If no StorageClass is specified, the default StorageClass is used.
- **defenderConfig** (PrismaCloudComputeDefenderConfig)  
Options for installing Defender.
They are ultimately passed to `twistcli` for YAML generation.
  - **defenderConfig.cluster** (string)  
  A cluster name to identify the openshift cluster.
  If no value specified, defender will try to automatically get the cluster name from the cloud provider.
  - **defenderConfig.clusterAddress** (string)  
  Host name used by Defender to verify Console certificate.
  Must be one of the SANs listed at Manage > Defenders > Names.
  - **defenderConfig.collectPodLabels** (string)  
  Must be true or false.
  - **defenderConfig.consoleAddress** (string)  
  URL of the Console.
  - **defenderConfig.docker** (string)  
  Hook into Docker runtime.
  Enable only if the cluster is using Docker.
  - **defenderConfig.dockerSocketPath** (string)  
  Path to docker.sock.
  Ignore if not using Docker.
  - **defenderConfig.imagePullSecret** (string)  
  Secret needed to pull the Defender image when using a private registry.
  - **defenderConfig.imageName** (string)  
  Defender image to deploy.
  If no value is specified, the image is pulled from the Prisma Cloud Compute registry.
  - **defenderConfig.monitorIstio** (string)  
  Must be true or false.
  - **defenderConfig.monitorServiceAccounts** (string)  
  Must be true or false.
  - **defenderConfig.nodeLabels** (string)  
  Label to use as a nodeSelector for Defenders. Specify a label and value (e.g. 'kubernetes.io/hostname: "node-name"').
  - **defenderConfig.privileged** (string)  
  Run Defender in privileged mode.
  Must be true or false.
  - **defenderConfig.project** (string)  
  Project to which Defenders will connect.
  - **defenderConfig.proxyAddress** (string)  
  Proxy address for Defender-to-Console communication.
  - **defenderConfig.proxyCa** (string)  
  Proxy's CA certificate for Console to trust, encoded in base64.
  Required when using TLS-intercept proxies.
  - **defenderConfig.proxyPassword** (string)  
  Password for authenticating with the proxy.
  - **defenderConfig.proxyUsername** (string)  
  Username for authenticating with the proxy.
  - **defenderConfig.selinuxEnabled** (string)  
  Use the spc_t SELinux type.
  Must be true or false.
  - **defenderConfig.toleration** (string)
  Deploy Defenders with a toleration.
  Must be true or false.
  - **defenderConfig.tolerationKey** (string)
  Taint key that the toleration applies to.
  Default is node-role.kubernetes.io/master.
  - **defenderConfig.tolerationEffect** (string)
  Taint effect to match.
  Default is NoSchedule.
