# OpenShift Offline Deployment

This documentation demonstrates the automated deployment of Prisma Cloud Compute (Console and Defenders) within an isolated OpenShift Container Platform 4.7 using the [Operators for isolated environments guidance](https://cloud.redhat.com/blog/is-your-operator-air-gap-friendly?extIdCarryOver=true&sc_cid=701600000006NHXAA2).

In this example we utilize the OCP built-in image registry for the storage of the Console, Defender and Operator images.
For access to the built-in registry from outside the cluster, we set the `defaultRoute` parameter of the `configs.imageregistry.operator.openshift.io` resource to `true`.
This procedure can be found [here](https://docs.openshift.com/container-platform/4.7/registry/securing-exposing-registry.html).
We then tag and push the images with the external registry repository path (e.g. default-route-openshift-image-registry.apps.example.com/twistlock).
If you do not intend to use the exteral route for the built-in registry, adjust the instructions accordingly.

## Instructions
On a host with docker or podman installed and has connectivity to the Internet:
1. Pull the required images.
    - the [operator image](https://quay.io/repository/prismacloud/pcc-operator) 
        ```bash
        docker pull quay.io/prismacloud/pcc-operator:v0.0.1
        ```
    - the [operator catalog image](https://quay.io/repository/prismacloud/pcc-operator-catalog)
        ```bash
        docker pull quay.io/prismacloud/pcc-operator-catalog:v0.0.1
        ```
    
    - the [Console and Defender images](https://docs.prismacloudcompute.com/docs/compute_edition/install/twistlock_container_images.html) for the product version you're trying to install
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

3. Move image tarballs to a host with docker or podman install and has access to the disconnected cluster.

4. Load the images.
    ```bash
    docker load -i pcc-operator.tar.gz
    docker load -i pcc-operator-catalog.tar.gz
    docker load -i kube-rbac-proxy.tar.gz
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
    
    **Important**: If you use the OCP built-in image registry, you'll have to create any Projects used in the image path before pushing the images.
    ```bash
    oc create ns twistlock
    ```
    ```bash
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```

7. Create the `CatalogSource` object that populates OperatorHub in the web console.

    Notice that the `image` specifies the OpenShift cluster's internal image-registry's service name and port (`image-registry.openshift-image-registry.svc.cluster.local:5000`).

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

5. In the OCP web console, navigate to **Operators** > **OperatorHub** and search for "Prisma Cloud Compute Operator".
Select the "disconnected" Operator.

6. Install the Prisma Cloud Compute Operator in the `twistlock` namespace.
    
7. Update the `pcc-operator` image defined in the Operator's ClusterServiceVersion.yaml 
    - Go to **Installed Operators** > **Prisma Cloud Compute Operator** > **YAML** 
    - Change 
        ```
        containerImage: quay.io/prismacloud/pcc-operator@sha256:13a8d407bb25bd398df728d57dd1656172ce95ab6161249ef37de0cc4421c2e6
        ``` 
        to
        ```
        containerImage: image-registry.openshift-image-registry.svc.cluster.local:5000/twistlock/pcc-operator@sha256:13a8d407bb25bd398df728d57dd1656172ce95ab6161249ef37de0cc4421c2e6
        ``` 
    
8. Install Console and/or Defender.
Refer to the [field necessity table](readme.md) for additional field details.
