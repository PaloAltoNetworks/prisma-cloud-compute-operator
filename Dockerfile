FROM quay.io/operator-framework/ansible-operator:v1.14.0

ARG VERSION
ARG RELEASE=1

# Switch to root to update image
# 1001 is the ansible user
# source: https://github.com/operator-framework/operator-sdk/blob/master/images/ansible-operator/Dockerfile#L24
USER 0
RUN dnf upgrade -y \
    && dnf clean all \
    && rm -rf /var/cache/{dnf,yum}
USER 1001

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
