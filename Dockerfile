# tag v1.8.1
FROM quay.io/operator-framework/ansible-operator@sha256:57fb89a088b538a2725963f463904634da4f8dc73066e990c8ce09d292f36bd0

ARG VERSION
ARG RELEASE=1

### Required OpenShift Labels
LABEL name="Prisma Cloud Compute Operator" \
      vendor="Palo Alto Networks" \
      version=$VERSION \
      release=$RELEASE \
      summary="Deploy Prisma Cloud Compute for cloud-native security in your clusters." \
      description="This operator will deploy Console and Defender to the cluster."

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

# Required Licenses
COPY licenses /licenses

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
