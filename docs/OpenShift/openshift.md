# OpenShift Deployment

This documentation demonstrates the automated [installation](#installation-process) and [upgrade](#upgrade-process) processes for the Prisma Cloud Compute Console and Defenders within an OpenShift Container Platform that is able to communicate with the [RedHat Community Operators](https://github.com/redhat-openshift-ecosystem/community-operators-prod/tree/main/operators) and the [Prisma Cloud Compute container registry](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/install/twistlock_container_images.html).

## Installation Process
1. Create the Project (namespace) for this deployment (e.g. `twistlock`).
    ```bash
    oc create ns twistlock
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
        oc apply -f pcc-credentials.yaml
        ```

3. In the OCP web console, navigate to **Operators > OperatorHub** and search for `Prisma Cloud Compute Operator`. Select the community Operator.

4. Install the Prisma Cloud Compute Operator in the `twistlock` namespace.

5. Install Console and Defenders.
    - Within the `twistlock` Project go to **Installed Operators > Prisma Cloud Compute Operator > Details**
    - Click **Create instance** in the `Console and Defender` provided API
    - In the `Tool Bundle URL` field specify the path to the update tool bundle matching the version to be deployed. The Prisma Cloud Compute release bundle can be used as well.  
    - Set `Version` to the version to be deployed (e.g. 21_08_520).
    If installing Defenders only, be sure to verify the version of your Console and use the same version for Defender deployment.
    - If you are not using Kubernetes Secrets set the following in the [Credentials](resource_spec.md) section: 

        - **Access Token**: 32-character access token included in the license bundle
        - **License**: Product license included in the license bundle
        - **Password**: Password to be used for the initial local administrator user. It is highly recommended that you change the password for this user in the Prisma Cloud Compute Console after install.
        - **Username**: Username to be used for the initial local administrator user.
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`
    - Confirm that the Console and Defender containers are running in **Workloads > Pods**

6. Create OpenShift external route to the Console
    - Go to **Networking > Routes**
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

7. Login with the username and password specified in the `Credentials` section. If you did not use Kubernetes Secrets reset this account's password in **Manage > Authentication > Users**.

## Upgrade Process
The upgrade process will retain the existing deployment's configuration and settings. Please consult the release notes first to determine if any additional procedures are required.  

### Console Upgrade
- Within the `twistlock` Project go to **Installed Operators > Prisma Cloud Compute Operator > Details**
    - Click **Create instance** in the `Console` provided API
    - In the `Orchestrator` field enter `openshift`
    - In the `Tool Bundle URL` field specify the path to the update tool bundle matching the version to be deployed. The Prisma Cloud Compute release bundle can be used as well.  
    - Set `Version` to the version to be deployed (e.g. 21_08_520)
    - If you are not using Kubernetes Secrets set the following in the `Credentials` section: 
        - **Access Token**: `license access token`
        - **License**: `license key`
        - **Password**: `admin account password`
        - **Username**: `admin account username`
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`

### Defender Upgrade
Once the upgraded Console has been deployed upgrade the Defenders.
- Within the `twistlock` Project go to **Installed Operators > Prisma Cloud Compute Operator > Details**
    - Click **Create instance** in the `Defender` provided API
    - In the `Tool Bundle URL` field specify the path to the update tool bundle matching the version to be deployed. The Prisma Cloud Compute release bundle can be used as well.   
    - Set `Version` to the version to be deployed (e.g. 21_08_520)
    - In the `Credentials` section: 
        - **Password**: password to an account that has defender-manager or higher role
        - **Username**: username to an account that has defender-manager or higher role
    - In the `Defender Installation Options` section:
        - **Cluster Address**: `twistlock-console` name of the Console's service
        - **Console Address**: `https://twistlock-console:8083` Console's service API endpoint
    - Refer to the [field necessity table](resource_spec.md) for additional field details.
    - Click `Create`
