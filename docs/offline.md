# Offline deployments

This documentation has been developed using OpenShift Container Platform 4.7 and utilizes the OCP built-in image registry.

For access to the built-in registry from outside the cluster, we set the `defaultRoute` parameter of the `configs.imageregistry.operator.openshift.io` resource to `true`.
This procedure can be found [here](https://docs.openshift.com/container-platform/4.7/registry/securing-exposing-registry.html).

If you do not intend use the default route for the built-in registry, adjust the instructions accordingly.

## Instructions
On a host with connectivity to the Internet:
1. Pull the required images.
    - the operator image
        ```bash
        docker pull quay.io/prismacloud/pcc-operator@GET_DIGEST
        ```
    - the operator catalog image
        ```bash
        docker pull quay.io/prismacloud/pcc-operator-catalog@GET_DIGEST
        ```
    - the proxy image for Kubernetes RBAC authorization (following the guidance [here](https://catalog.redhat.com/software/containers/openshift4/ose-kube-rbac-proxy/5cdb2634dd19c778293b4d98?tag=v4.8.0-202106291913.p0.git.813c3da.assembly.stream&push_date=1624999701000&container-tabs=gti) if necessary)
        ```bash
        docker pull registry.redhat.io/openshift4/ose-kube-rbac-proxy@sha256:f85766573467db25a9e12ee1f75a8315b15a775c76da55e84a36602bca5a1d33
        ```
    - the [Console and Defender images](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/install/twistlock_container_images.html) for the product version you're trying to install
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

3. Move image tarballs to a host with access to the disconnected cluster.

4. Load the images.
    ```bash
    docker load -i pcc-operator.tar.gz
    docker load -i pcc-operator-catalog.tar.gz
    docker load -i kube-rbac-proxy.tar.gz
    docker load -i console.tar.gz
    docker load -i defender.tar.gz
    ```

5. Tag the images.
    ```bash
    docker tag 5528a99e7867 default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker tag 0e8b1a0d7ac4 default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker tag 22f9d22875f8 default-route-openshift-image-registry.apps.example.com/twistlock/ose-kube-rbac-proxy:v4.8.0
    docker tag 5f2561fab847 default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker tag 8d82e2c21c33 default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```
6. Push the images to your disconnected registry.
    
    **Important**: If you use the OCP built-in image registry, you'll have to create any namespaces used in the image path before pushing the images.
    ```bash
    oc create ns twistlock
    ```
    ```bash
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/pcc-operator:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog:v0.0.1
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/ose-kube-rbac-proxy:v4.8.0
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/console:console_21_04_439
    docker push default-route-openshift-image-registry.apps.example.com/twistlock/defender:defender_21_04_439
    ```

7. Create the `CatalogSource` object that populates OperatorHub in the web console.

    Notice that the `image` specifies the same route.
    You can also use the registry's `Service` name and port (`image-registry.openshift-image-registry.svc.cluster.local:5000`).

    ```yaml
    apiVersion: operators.coreos.com/v1alpha1
    kind: CatalogSource
    metadata:
      name: pcc-operator-catalog
      namespace: openshift-marketplace
    spec:
      sourceType: grpc
      image: default-route-openshift-image-registry.apps.example.com/openshift-marketplace/pcc-operator-catalog
      displayName: Prisma Cloud Compute Operator Catalog
      publisher: Palo Alto Networks
      updateStrategy:
        registryPoll:
          interval: 10m0s
    ```

5. In the OCP web console, navigate to **Operators** > **OperatorHub** and search for "Prisma Cloud Compute Operator".

6. Install the Prisma Cloud Compute Operator in the `twistlock` namespace.
    - You can go to **Workloads** > **Pods** in the `twistlock` project to verify that the `pcc-operator-controller-manager` pod is running.
    If it isn't, try the following:
        1. Go to **Operators** > **Installed Operators**
        2. Select the Prisma Cloud Compute Operator
        3. Select the YAML tab
        4. Update all the image references under `.spec.install.spec.deployments` to use the disconnected registry

7. Install Console and/or Defender.
Refer to the [field necessity table](readme.md) for additional field details.
