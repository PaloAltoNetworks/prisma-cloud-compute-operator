# OpenShift Offline Deployment

This documentation demonstrates the automated [installation](#installation-process) and [upgrade](#upgrade-process) processes for the Prisma Cloud Compute Console and Defenders within an isolated OpenShift Container Platform 4.7 using the [Operators for isolated environments guidance](https://cloud.redhat.com/blog/is-your-operator-air-gap-friendly?extIdCarryOver=true&sc_cid=701600000006NHXAA2).

In this example we utilize the OCP built-in image registry for the storage of the Console, Defender and Operator images.
For access to the built-in registry from outside the cluster, we set the `defaultRoute` parameter of the `configs.imageregistry.operator.openshift.io` resource to `true`.
This procedure can be found [here](https://docs.openshift.com/container-platform/4.7/registry/securing-exposing-registry.html).
We then tag and push the images with the external registry repository path (e.g. default-route-openshift-image-registry.apps.example.com/twistlock).
If you do not intend to use the external route for the built-in registry, adjust the instructions accordingly.

## Installation Process
On a host that has docker or podman installed and has connectivity to the Internet:
1. Pull the required images.
    - the [operator image](https://quay.io/repository/prismacloud/pcc-operator) 
        ```bash
        docker pull quay.io/prismacloud/pcc-operator:v0.0.1
        ```
    - the [operator catalog image](https://quay.io/repository/prismacloud/pcc-operator-catalog)
        ```bash
        docker pull quay.io/prismacloud/pcc-operator-catalog:v0.0.1
        ```
    
    - the [Console and Defender images](https://docs.prismacloudcompute.com/docs/compute_edition/install/twistlock_container_images.html) for the version you are installing
        ```bash
        docker pull registry.twistlock.com/twistlock/console:console_21_04_439
        docker pull registry.twistlock.com/twistlock/defender:defender_21_04_439
        ```

2. Save the images as tarballs.
    ```bash
    docker save quay.io/prismacloud/pcc-operator:v0.0.1 | gzip > pcc-operator.tar.gz
    docker save quay.io/prismacloud/pcc-operator-catalog:v0.0.1 | gzip > pcc-operator-catalog.tar.gz
    docker save registry.twistlock.com/twistlock/console:console_21_04_439 | gzip > console.tar.gz
    docker save registry.twistlock.com/twistlock/defender:defender_21_04_439 | gzip > defender.tar.gz
    ```

3. Move the image tarballs to a host that has docker or podman installed and has access to the disconnected cluster.

4. Load the images.
    ```bash
    docker load -i pcc-operator.tar.gz
    docker load -i pcc-operator-catalog.tar.gz
    docker load -i console.tar.gz
    docker load -i defender.tar.gz
    ```

5. Tag the images for your disconnected registry.
    ```bash
    docker tag quay.io/prismacloud/pcc-operator:v0.0.1 default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker tag quay.io/prismacloud/pcc-operator-catalog:v0.0.1 default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker tag registry.twistlock.com/twistlock/console:console_21_04_439 default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker tag registry.twistlock.com/twistlock/defender:defender_21_04_439 default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```
6. Push the images to your disconnected registry.
    
    **Important**: If you use the OCP built-in image registry, you'll have to create the Projects (namespaces) used in the image path before pushing the images.
    ```bash
    oc create ns twistlock
    ```
    ```bash
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```

7. Create the `CatalogSource` object that populates OperatorHub in OpenShift.

    Notice that the `image` specifies the OpenShift cluster's internal image-registry's service name and port (`image-registry.openshift-image-registry.svc.cluster.local:5000`).

    - Copy the following yaml into a file called `catalogsource.yaml`
        ```yaml
        apiVersion: operators.coreos.com/v1alpha1
        kind: CatalogSource
        metadata:
        name: pcc-operator-catalog
        namespace: openshift-marketplace
        spec:
        sourceType: grpc
        image: image-registry.openshift-image-registry.svc.cluster.local:5000/openshift-marketplace/pcc-operator-catalog
        displayName: Prisma Cloud Compute Operator Catalog
        publisher: Palo Alto Networks
        updateStrategy:
            registryPoll:
            interval: 10m0s
        ```
    - Apply the CatalogSource yaml to the cluster
        ```bash
        oc apply -f catalogsource.yaml
        ```


5. In the OCP web console, navigate to **Operators** > **OperatorHub** and search for `Prisma Cloud Compute Operator`.
You can apply the `Infrastructure features: disconnected` filter to refine the search.

6. Install the Prisma Cloud Compute Operator in the `twistlock` namespace.
    
7. Update the `pcc-operator` image defined in the Operator's ClusterServiceVersion.yaml `deployments.spec.template.spec.containers` element. 
    - Go to **Installed Operators** > **Prisma Cloud Compute Operator** > **YAML** 
    - Change 
        ```
        image: quay.io/prismacloud/pcc-operator@sha256:13a8d407bb25bd398df728d57dd1656172ce95ab6161249ef37de0cc4421c2e6
        ``` 
        to
        ```
        image: image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/pcc-operator@sha256:13a8d407bb25bd398df728d57dd1656172ce95ab6161249ef37de0cc4421c2e6
        ``` 
    - Click `Save`

8. Install Console and Defenders.
    - Go to **Installed Operators** > **Prisma Cloud Compute Operator** > **Details**
    - Click **Create instance** in the `Console and Defender` provided API
    - In the `Tool Bundle URL` field specify the path to the [offline update tool bundle](https://docs.prismacloudcompute.com/docs/government/isolated_upgrades/isolated_upgrades.html) matching your version to be deployed. Host this tar.gz file in an http/https location where your isolated cluster can reach and pull this file. The [Prisma Cloud Compute release bundle](https://docs.prismacloudcompute.com/docs/releases/release-information/download.html) can be used as well.  
    - Set `Version` to the version to be deployed (e.g. 21_04_439)
    - In the `Credentials` section: 
        - **Access Token**: 32-character (lower case) access token included in the license bundle
        - **License**: Product license included in the license bundle
        - **Password**: Password to be used for the initial local administrator user. It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install.
        - **Username**: Username to be used for the initial local administrator user.
    - In the `Console Installation Options` section:
        - **Image Name**: `image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/console:console_21_04_439`
    - In the `Defender Installation Options` section:
        - **Image Name**: `image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/defender:defender_21_04_439`
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`
    - Confirm that the Console and Defender containers are running in **Workloads**>**Pods**

9. Create OpenShift external route to the Console
    - Go to **Networking**>**Routes**
    - Click `Create Route`
        - Provide a `name` for the route (e.g. twistlock-console)
        - Leave `hostname` empty, Openshift will generate the FQDN based upon the route name (e.g. https://twistlock-console.apps.example.com)
        - Drop down `Service` menu and select `twistlock-console`
        - Drop down `Target port` menu and select `8083 -> 8083 (TCP)`
        - Click the `Secure route` radio button 
        - Set `TLS Termination` = `Passthrough`
        - Drop down `Insecure Traffic` menu and select `Redirect`
        - Click `Create`
    - Browse to the newly created external router (e.g. https://twistlock-console.apps.example.com)

10. Login with the username and password specified in the `Credentials` section. It is highly recommended that you change the password for this account in the **Manage**>**Authentication**>**Users**.

## Upgrade Process
The upgrade process will retain the existing deployment's configuration and settings. Upload the new Prisma Cloud Compute Console and Defender images as described in the [intallation process](#installation-process) to the isolated cluster. Please consult the [release notes](https://docs.prismacloudcompute.com/docs/releases/release-information/latest.html) first to determine if any additional procedures are required.  

### Console Upgrade
- Go to **Installed Operators** > **Prisma Cloud Compute Operator** > **Details**
    - Click **Create instance** in the `Console` provided API
    - In the `Tool Bundle URL` field specify the path to the [offline update tool bundle](https://docs.prismacloudcompute.com/docs/government/isolated_upgrades/isolated_upgrades.html) matching your version to be deployed. Host this tar.gz file in an http/https location where your isolated cluster can reach and pull this file. The [Prisma Cloud Compute release bundle](https://docs.prismacloudcompute.com/docs/releases/release-information/download.html) can be used as well.  
    - Set `Version` to the version to be deployed (e.g. 21_04_439)
    - In the `Credentials` section: 
        - **Access Token**: <`clear this value`>
        - **License**: <`clear this value`>
        - **Password**: <`clear this value`>
        - **Username**: <`clear this value`>
    - In the `Console Installation Options` section:
        - **Image Name**: `image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/console:console_21_04_439`
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`

### Defender Upgrade
Once the upgraded Console has been deployed upgrade the Defenders.
- Go to **Installed Operators** > **Prisma Cloud Compute Operator** > **Details**
    - Click **Create instance** in the `Defender` provided API
    - In the `Tool Bundle URL` field specify the path to the [offline update tool bundle](https://docs.prismacloudcompute.com/docs/government/isolated_upgrades/isolated_upgrades.html) matching your version to be deployed. Host this tar.gz file in an http/https location where your isolated cluster can reach and pull this file. The [Prisma Cloud Compute release bundle](https://docs.prismacloudcompute.com/docs/releases/release-information/download.html) can be used as well.   
    - Set `Version` to the version to be deployed (e.g. 21_04_439)
    - In the `Credentials` section: 
        - **Password**: password to an account that has defender-manager or higher role
        - **Username**: username to an account that has defender-manager or higher role
    - In the `Defender Installation Options` section:
        - **Cluster Address**: `twistlock-console` name of the Console's service
        - **Console Address**: `https://twistlock-console:8083` Console's service API endpoint
        - **Image Name**: `image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/defender:defender_21_04_439`
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`

