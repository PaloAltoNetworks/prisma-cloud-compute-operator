# Kubernetes Offline Deployment

This documentation demonstrates the automated [installation](#installation-process) and [upgrade](#upgrade-process) processes for the Prisma Cloud Compute Console and Defenders within a Kubernetes cluster that is unable to communicate with the Internet.

## Collect PCC-Operator Components
1. Pull the required images.
    - the [operator image](https://quay.io/repository/prismacloud/pcc-operator) 
        ```bash
        docker pull quay.io/prismacloud/pcc-operator:v0.1.1
        ```

    - the [Console and Defender images](https://docs.prismacloudcompute.com/docs/compute_edition/install/twistlock_container_images.html) for the version you are installing
        ```bash
        docker pull registry.twistlock.com/twistlock/console:console_21_08_514
        docker pull registry.twistlock.com/twistlock/defender:defender_21_08_514
        ```

2. Save the images as tarballs.
    ```bash
    docker save quay.io/prismacloud/pcc-operator:v0.1.1 | gzip > pcc-operator.tar.gz
    docker save registry.twistlock.com/twistlock/console:console_21_08_514 | gzip > console.tar.gz
    docker save registry.twistlock.com/twistlock/defender:defender_21_08_514 | gzip > defender.tar.gz
    ```

3. Pull the PaloAltoNetworks/prisma-cloud-compute-operator GitHub repo.
    ```bash
    wget https://github.com/PaloAltoNetworks/prisma-cloud-compute-operator/archive/refs/heads/main.zip 
    ```

4. Pull the `Tool Bundle URL` field specify the path to the [offline update tool bundle](https://docs.prismacloudcompute.com/docs/government/isolated_upgrades/isolated_upgrades.html) matching the version to be deployed. The [Prisma Cloud Compute release bundle](https://docs.paloaltonetworks.com/prisma/prisma-cloud/21-08/prisma-cloud-compute-edition-release-notes/release-information/release-notes-21-08.html) can be used as well.   
    ```bash
    wget https://cdn.twistlock.com/isolated_upgrades/v21_08_514/v21_08_514_isolated_update.tar.gz
    ```

5. Move the image tarballs, the GitHub repo zip file and offline update tool bundle to a host that has docker installed and has access to the disconnected cluster.

6. Docker load, tag and push the images to a registry that is accessible (e.g. 10.105.219.150) from your isolated Kubernetes cluster.
    ```bash
    docker load < pcc_operator.tar.gz
    docker tag 3eee0ee3aef5 10.105.219.150/pcc-operator:v0.1.1
    docker push 10.105.219.150/pcc-operator:v0.1.1

    docker load < console.tar.gz
    docker tag 58c779558b27 10.105.219.150/console:console_21_08_514
    docker push 10.105.219.150/console:console_21_08_514

    docker load < defender.tar.gz
    docker tag aaf13f247f08 10.105.219.150/defender:defender_21_08_514
    docker push 10.105.219.150/defender:defender_21_08_514
    ```

7. Host the offline update tool bundle v21_08_514_isolated_update.tar.gz file in an http/https location where your isolated cluster can reach and pull this file. For example, http://192.168.49.2:30001/v21_08_514_isolated_update.tar.gz

8. Unzip the PaloAltoNetworks/prisma-cloud-compute-operator GitHub repo.
    ```bash 
    unzip main.zip
    ```

## Installation Process
1. Create the namespace for this deployment (e.g. `twistlock`).
    ```bash
    kubectl create ns twistlock
    ```

2. The Console is licensed and the intial administrator account is created during deployment. The account credentials and license can be supplied as arguments or as a Kubernetes Secret. To deploy using a Kubernetes Secret:
    - Copy the following yaml into a file called [pcc-credentials.yaml](pcc-credentials.yaml).
    
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
    
    - Base64 encode your `accessToken`, `license`, `password` & `username` values and update the `pcc-credentials.yaml` file. For example: ```echo -n "admin" | base64``` output: ```YWRtaW4=``` 
    
    - Create the secret within the cluster.
        ```bash
        kubectl apply -f pcc-credentials.yaml
        ```

3. Modify the unzipped GitHub repo's config/manager/kustomization.yaml from: 
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - manager.yaml

    images:
    - digest: sha256:e5c9c4947755399481aa81d8ffc37543f3fcc81de8052a711cf836c83e6efa7b
    name: controller
    newName: quay.io/prismacloud/pcc-operator
    ```
    to:
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - manager.yaml

    images:
    - name: controller
    newName: 10.105.219.150/pcc-operator
    newTag: v0.1.1
    ```

4. Change directory to the GitHub repo's config/deploy and deploy the pcc-operator. 
    ```bash
    kubectl apply -k .
    ```

5. Install Console and Defenders.
    - Copy the following yaml into a file called [consoledefender.yaml](consoledefender.yaml).
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
          version: '21_08_514'
          toolBundleUrl: http://192.168.49.2:30001/v21_08_514_isolated_update.tar.gz
          consoleConfig:
            serviceType: ClusterIP
            imageName: 10.105.219.150/console:console_21_08_514
          defenderConfig:
            docker: true
            imageName: 10.105.219.150/defender:defender_21_08_514
        ```
        **NOTES:**
        - For docker-based clusters set `docker: true`.
        - The default `serviceType` is `NodePort`.
        
    - Set `version` to the Prisma Cloud Compute release version to be deployed (e.g. 21_08_514).

    - Set `toolBundleUrl` to the offline update tool bundle v21_08_514_isolated_update.tar.gz URL. For example, http://192.168.49.2:30001/v21_08_514_isolated_update.tar.gz
    
    - If you are not using Kubernetes Secrets set the following in the [Credentials](resource_spec.md) section: 
        - **Access Token**: 32-character access token included in the license bundle
        - **License**: Product license included in the license bundle
        - **Password**: Password to be used for the initial local administrator user. It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install.
        - **Username**: Username to be used for the initial local administrator user.
          
    - Deploy the Console and Defender. 
        ```bash
        kubectl apply -f ./consoledefender.yaml
        ```
   
    - Confirm that the Console and Defender pods have been deployed.
         ```bash
         kubectl get pods -n twistlock 
         ```

   
6. Establish communications to the twistlock-console service’s management-port-https port (default 8083/TCP) using a Kubernetes LoadBalancer or your organization’s approved cluster ingress technology. 
    
7. Login with the username and password specified in the `Credentials` section. If you did not use Kubernetes Secrets reset this account's password in **Manage**>**Authentication**>**Users**.

## Upgrade Process
The upgrade process will retain the existing deployment's configuration and settings. Please consult the [release notes](https://docs.prismacloudcompute.com/docs/releases/release-information/latest.html) first to determine if any additional procedures are required.  

### Console Upgrade
- Upgrade the Console.
    - Copy the following yaml into a file called [console.yaml](console.yaml).
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
          version: '21_08_514'
          toolBundleUrl: http://192.168.49.2:30001/v21_08_514_isolated_update.tar.gz
          consoleConfig:
            serviceType: ClusterIP
            imageName: 10.105.219.150/console:console_21_08_514
        ```
        **NOTES:**
        - The default `serviceType` is `NodePort`.
    
    - Set **version** to the Prisma Cloud Compute release version to be deployed (e.g. 21_08_514) section.

    - Set `toolBundleUrl` to the offline update tool bundle v21_08_514_isolated_update.tar.gz URL. For example, http://192.168.49.2:30001/v21_08_514_isolated_update.tar.gz 
        
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    
    - Deploy the Console. 
        ```bash
        kubectl apply -f ./console.yaml
        ```

### Defender Upgrade
 - Upgrade the Defenders.
    - Copy the following yaml into a file called [defender.yaml](defender.yaml).
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
        version: '21_08_514'
        defenderConfig:
            clusterAddress: twistlock-console
            consoleAddress: https://twistlock-console:8083
            imageName: 10.105.219.150/defender:defender_21_08_514
            docker: true
        ```    
        **NOTES:**
        - Ensure the version of your Console is the same version for Defender deployment.
        - For docker-based clusters set `docker: true`.

    - Set **version** to the version to be deployed (e.g. 21_08_514).
        
    - If you are not using Kubernetes Secrets set the following in the [Credentials](resource_spec.md) section: 
        - **Password**: password to an account that has defender-manager or higher role
        - **Username**: username to an account that has defender-manager or higher role
    
    - Deploy the Defenders.
        ```bash
        kubectl apply -f ./defender.yaml
        ```
