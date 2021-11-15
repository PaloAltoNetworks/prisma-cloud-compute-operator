# Kubernetes Deployment

This documentation demonstrates the automated [installation](#installation-process) and [upgrade](#upgrade-process) processes for the Prisma Cloud Compute Console and Defenders within a Kubernetes cluster that is able to communicate with the [Kubernetes Community Operators](https://github.com/k8s-operatorhub/community-operators/tree/main/operators) and the [Prisma Cloud Compute container registry](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/install/twistlock_container_images.html).

## Installation Process
1. Create the namespace for this deployment (e.g. `twistlock`).
    ```bash
    kubectl create ns twistlock
    ```

2. The Console is licensed and the intial administrator account is created during deployment. The account credentials and license can be supplied as arguments or as a Kubernetes Secret. To deploy using a Kubernetes Secret:
    - Copy the following yaml into a file called [pcc-credentials.yaml](pcc-credentials.yaml)
    
        ```yaml
        apiVersion: v1
        kind: Secret
        metadata:
          name: pcc-credentials
          namespace: twistlock
        data:
          accessToken: <base64 encoded access token>
          license: <base64 encoded license key>
          password: <base64 encoded password>
          username: <base64 encoded username>
        ```
    
    - Base64 encode your `accessToken`, `license`, `password`, and `username` values and update the `pcc-credentials.yaml` file. For example:
        ```bash
        $ echo -n "admin" | base64
        YWRtaW4=
        ```
    
    - Create the secret within the cluster.
        ```bash
        kubectl apply -f pcc-credentials.yaml
        ```

3. Install the latest [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/releases)
    ```bash
    curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.19.1/install.sh -o install.sh
    chmod +x install.sh
    ./install.sh v0.19.1
    ```

4. Install the Prisma Cloud Compute Operator in the `twistlock` namespace.
    - Copy the following yaml into a file called [operator.yaml](operator.yaml)
        ```yaml
        ---
        apiVersion: operators.coreos.com/v1
        kind: OperatorGroup
        metadata:
          name: pcc-operator
          namespace: twistlock
        spec:
          targetNamespaces:
          - twistlock
        ---
        apiVersion: operators.coreos.com/v1alpha1
        kind: Subscription
        metadata:
          name: pcc-operator
          namespace: twistlock
        spec:
          channel: stable
          name: pcc-operator
          source: operatorhubio-catalog
          sourceNamespace: olm
        ```
    - Deploy the Operator 
        ```bash
        kubectl apply -f ./operator.yaml
        ```

5. Install Console and Defenders.
    - Copy the following yaml into a file called [consoledefender.yaml](consoledefender.yaml)
        ```yaml
        --- 
        apiVersion: pcc.paloaltonetworks.com/v1alpha1
        kind: ConsoleDefender
        metadata:
          name: pcc-consoledefender
          namespace: twistlock
        spec:
          namespace: twistlock
          orchestrator: kubernetes
          version: '21_08_520'
          consoleConfig:
            serviceType: ClusterIP
          defenderConfig:
            docker: false
        ```
        **NOTES:**
        - If installing Defenders only, be sure to verify the version of your Console and use the same version for Defender deployment.
        - For docker-based clusters set `docker: true`.
        - The default `serviceType` is `NodePort`.
        
    - Set `version` to the Prisma Cloud Compute release version to be deployed (e.g. 21_08_520)

    - If you are not using Kubernetes Secrets set the following in the [Credentials](resource_spec.md) section: 
        - **Access Token**: 32-character access token included in the license bundle
        - **License**: Product license included in the license bundle
        - **Password**: Password to be used for the initial local administrator user. It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install.
        - **Username**: Username to be used for the initial local administrator user.
          
    - Deploy the Console and Defender 
        ```bash
        kubectl apply -f ./consoledefender.yaml
        ```
   
    - Confirm that the Console and Defender pods have been deployed.
         ```bash
         kubectl get pods -n twistlock 
         ```

   
6. Establish communications to the twistlock-console service’s management-port-https port (default 8083/TCP) using a Kubernetes LoadBalancer or your organization’s approved cluster ingress technology. 
    
7. Login with the username and password specified in the `Credentials` section. If you did not use Kubernetes Secrets reset this account's password in **Manage > Authentication > Users**.

## Upgrade Process
The upgrade process will retain the existing deployment's configuration and settings. Please consult the release notes first to determine if any additional procedures are required.  

### Console Upgrade
- Upgrade the Console.
    - Copy the following yaml into a file called [console.yaml](console.yaml)
        ```yaml
        ---
        apiVersion: pcc.paloaltonetworks.com/v1alpha1
        kind: Console
        metadata:
          name: pcc-console
          namespace: twistlock
        spec:
          namespace: twistlock
          orchestrator: kubernetes
          version: '21_08_520'
          consoleConfig:
            serviceType: ClusterIP
        ```
        **NOTES:**
        - The default `serviceType` is `NodePort`.
    
    - Set **version** to the Prisma Cloud Compute release version to be deployed (e.g. 21_08_520) section 
        
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    
    - Deploy the Console 
        ```bash
        kubectl apply -f ./console.yaml
        ```

### Defender Upgrade
 - Upgrade the Defenders.
    - Copy the following yaml into a file called [defender.yaml](defender.yaml)
        ```yaml
        ---
        apiVersion: pcc.paloaltonetworks.com/v1alpha1
        kind: Defender
        metadata:
        name: pcc-defender
        namespace: twistlock
        spec:
        namespace: twistlock
        orchestrator: kubernetes
        version: '21_08_520'
        defenderConfig:
          clusterAddress: twistlock-console
          consoleAddress: https://twistlock-console:8083
          docker: false
        ```    
        **NOTES:**
        - For docker-based clusters set `docker: true`.

    - Set **version** to the version to be deployed (e.g. 21_08_520).
        
    - If you are not using Kubernetes Secrets set the following in the [Credentials](resource_spec.md) section: 
        - **Password**: password to an account that has defender-manager or higher role
        - **Username**: username to an account that has defender-manager or higher role
    
    - Deploy the Defenders 
        ```bash
        kubectl apply -f ./defender.yaml
        ```
