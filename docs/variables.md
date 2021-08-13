# Additional field information

## Notes

- `.spec.toolBundleUrl` expects a link to one of the `*_isolated_update.tar.gz` files found here: https://docs.twistlock.com/docs/government/isolated_upgrades/isolated_upgrades.html.
  - If `.spec.toolBundleUrl` is not specified, the tool bundle URL is built using `.spec.version`.
- If `.spec.consoleConfig.imageName` is not specified, the image name is built using `.spec.version` and `.spec.credentials.accessToken`.

| Field | Description | Required? | Default value |
| --- | --- | --- | --- |
| `.spec.namespace` | Namespace in which the Console and Defenders will be deployed. This should be the same namespace as the operator itself. | Yes | `twistlock` |
| `.spec.orchestrator` | Orchestrator being used. Must be "kubernetes" or "openshift". | Yes | `openshift` |
| `.spec.toolBundleUrl` | URL of the tool bundle containing twistcli, the tool used to generate Prisma Cloud Compute YAML files. |  |  |
| `.spec.version` | Version of Prisma Cloud Compute to install. | Yes | `21_04_439` |
| `.spec.credentials.accessToken` | 32-character access token included in the license bundle. | Yes | `access_token` |
| `.spec.credentials.license` | Product license included in the license bundle. | Yes | `license` |
| `.spec.credentials.password` | Password to be used for the initial local administrator user. It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install. | Yes | `change_me_after_install` |
| `.spec.credentials.username` | Username to be used for the initial local administrator user. | Yes | `admin` |
| `.spec.consoleConfig.imagePullSecret` | Secret needed to pull the Console image when using a private registry. |  |  |
| `.spec.consoleConfig.imageName` | Console image to deploy. If no value is specified, the image is pulled from the Prisma Cloud Compute registry. |  |  |
| `.spec.consoleConfig.nodeLabels` | Label to use as a nodeSelector for Console. Specify a label and value (e.g. "kubernetes.io/hostname=node-name"). |  |  |
| `.spec.consoleConfig.persistentVolumeLabels` | Label to match the PVC to the PV. |  |  |
| `.spec.consoleConfig.persistentVolumeStorage` | Storage size of the PV (default "100Gi"). |  |  |
| `.spec.consoleConfig.runAsUser` | Run Console as UID 2674 (requires manual pre-configuration of ownership and permissions of the PV). |  |  |
| `.spec.consoleConfig.serviceType` | Service type for exposing Console. Supported values are "ClusterIP", "NodePort", and "LoadBalancer". |  | `ClusterIP` |
| `.spec.consoleConfig.storageClass` | StorageClass to use when dynamically provisioning a PV for Console. A PV is dynamically provisioned if twistcli cannot find the PV specified with the Persistent Volume Label option. If no StorageClass is specified, the default StorageClass is used. |  |  |
| `.spec.defenderConfig.clusterAddress` | Host name used by Defender to verify Console certificate. Must be one of the SANs listed at Manage > Defenders > Names. | Yes | `twistlock-console.example.com` |
| `.spec.defenderConfig.collectPodLabels` |  |  | `false` |
| `.spec.defenderConfig.consoleAddress` | URL of the Console. | Yes | `https://twistlock-console.example.com:8083` |
| `.spec.defenderConfig.docker` | Hook into Docker runtime. Enable only if the cluster is using Docker. |  | `false` |
| `.spec.defenderConfig.dockerSocketPath` | Path to docker.sock. Ignore if not using Docker. |  |  |
| `.spec.defenderConfig.imagePullSecret` | Secret needed to pull the Defender image when using a private registry. |  |  |
| `.spec.defenderConfig.imageName` | Defender image to deploy. If no value is specified, the image is pulled from the Prisma Cloud Compute registry. |  |  |
| `.spec.defenderConfig.monitorIstio` |  |  | `false` |
| `.spec.defenderConfig.monitorServiceAccounts` |  |  | `true` |
| `.spec.defenderConfig.nodeLabels` | Label to use as a nodeSelector for Defenders. Specify a label and value (e.g. "kubernetes.io/hostname=node-name"). |  |  |
| `.spec.defenderConfig.privileged` | Run Defender in privileged mode. |  | `false` |
| `.spec.defenderConfig.project` | Project to which Defenders will connect. |  |  |
| `.spec.defenderConfig.proxyAddress` | Proxy address for Defender-to-Console communication. |  |  |
| `.spec.defenderConfig.proxyCa` | Proxy's CA certificate for Console to trust, encoded in base64. Required when using TLS-intercept proxies. |  |  |
| `.spec.defenderConfig.proxyPassword` | Password for authenticating with the proxy. |  |  |
| `.spec.defenderConfig.proxyUsername` | Username for authenticating with the proxy. |  |  |
| `.spec.defenderConfig.selinuxEnabled` | Use the spc_t SELinux type. |  | `false` |
