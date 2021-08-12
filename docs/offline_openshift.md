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
        - tag: v0.0.1 
        - digest: sha256:13a8d407bb25bd398df728d57dd1656172ce95ab6161249ef37de0cc4421c2e6 
        ```bash
        docker pull quay.io/prismacloud/pcc-operator:v0.0.1
        ```
    - the [operator catalog image](https://quay.io/repository/prismacloud/pcc-operator-catalog)
        - tag: v0.0.1
        - digest: @sha256:f20a2b77e0386449b8123f3a3fa6f184316757e3e966c6ff529a76d09c6e24d1
        ```bash
        docker pull quay.io/prismacloud/pcc-operator-catalog:v0.0.1
        ```
    - the proxy image for Kubernetes RBAC authorization (following the guidance [here](https://catalog.redhat.com/software/containers/openshift4/ose-kube-rbac-proxy/5cdb2634dd19c778293b4d98?tag=v4.8.0-202106291913.p0.git.813c3da.assembly.stream&push_date=1624999701000&container-tabs=gti) if necessary) 
        - tag: v4.8.0-202107291502.p0.git.813c3da.assembly.stream
        - digest: @sha256:6d57bfd91fac9b68eb72d27226bc297472ceb136c996628b845ecc54a48b31cb
        ```bash
        docker pull registry.redhat.io/openshift4/ose-kube-rbac-proxy:v4.8.0-202107291502.p0.git.813c3da.assembly.stream
        ```
        **Important**: If you use a different image for the ose-kube-rbac-proxy update the clusterserviceversion.yaml with the image's digest value.

    - the [Console and Defender images](https://docs.prismacloudcompute.com/docs/compute_edition/install/twistlock_container_images.html) for the product version you're trying to install
        ```bash
        docker pull registry.twistlock.com/twistlock/console:console_21_04_439
        docker pull registry.twistlock.com/twistlock/defender:defender_21_04_439
        ```

2. Save the images as tarballs.
    ```bash
    docker save 5528a99e7867 | gzip > pcc-operator.tar.gz
    docker save 0e8b1a0d7ac4 | gzip > pcc-operator-catalog.tar.gz
    docker save 22f9d22875f8 | gzip > kube-rbac-proxy.tar.gz
    docker save 5f2561fab847 | gzip > console.tar.gz
    docker save 8d82e2c21c33 | gzip > defender.tar.gz
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
    docker tag 5528a99e7867 default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker tag 0e8b1a0d7ac4 default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker tag 22f9d22875f8 default-route-openshift-image-registry.apps.example.com/twistlock/ose-kube-rbac-proxy:v4.8.0-202107291502.p0.git.813c3da.assembly.stream
    docker tag 5f2561fab847 default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker tag 8d82e2c21c33 default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```
6. Push the images to your disconnected registry.
    
    **Important**: If you use the OCP built-in image registry, you'll have to create any Projects used in the image path before pushing the images.
    ```bash
    oc create ns twistlock
    ```
    ```bash
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/ose-kube-rbac-proxy:v4.8.0-202107291502.p0.git.813c3da.assembly.stream
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
    - You can go to **Workloads** > **Pods** in the `twistlock` project to verify that the `pcc-operator-controller-manager` pod is running.
    If it isn't, try the following:
        1. Go to **Operators** > **Installed Operators**
        2. Select the Prisma Cloud Compute Operator
        3. Select the YAML tab
        4. Update all the image references under `.spec.install.spec.deployments` to use the disconnected registry

7. Install Console and/or Defender.
Refer to the [field necessity table](readme.md) for additional field details.
