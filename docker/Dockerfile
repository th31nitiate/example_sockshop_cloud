FROM gcr.io/cloud-builders/gcloud

COPY helm.bash /helm.bash

RUN chmod +x /helm.bash
RUN curl -L https://get.helm.sh/helm-v2.16.12-linux-amd64.tar.gz -o /tmp/helm.tar.gz && tar xvf /tmp/helm.tar.gz -C /tmp/ && cp /tmp/linux-amd64/helm /helm && cp /tmp/linux-amd64/tiller /tiller
EXPOSE 44134
USER 65534
ENTRYPOINT ["/tiller"]