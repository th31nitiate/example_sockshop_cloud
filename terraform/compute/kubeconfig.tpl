apiVersion: v1
kind: Config
current-context: ${context}
clusters:
- cluster:
    certificate-authority-data: "${certificate_authority_data}"
    server: https://${server}
    insecure-skip-tls-verify: false
  name: ${context}
contexts:
- context:
    cluster: ${context}
    user: ${context}
  name: ${context}
users:
- name: ${context}
  user:
    username: client
    client-certificate-data: "${client_certificate_data}"
    client-key-data: "${client_key_data}"