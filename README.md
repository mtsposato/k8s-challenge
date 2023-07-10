# Kuebernetes challenge

Questa challenge si divide in tre fasi:

- Provisioning dell'infrastruttura
- Configurazione dell'infrastrattura
- Deploy di un applicazione

## Provisioning
L'infrastruttura verrà deployata su GCP tramite terraform.
Terraform è stato scelto poichè tra tutti i tool disponibili possiede la maggiore versaitilità e la minore complessità.
Lo script terraform deploya le seguenti risorse:
- 1 network
- 1 subnet
- 1 firewall rule
- 3 virtual machine

Per il corretto funzionamento è necessario valorizare le seguenti variabili:

```tf
project          = ""
credentials_file = ""
ip_range         = ""
region           = ""
zone             = ""
ssh_key          = ""
machine_type     = ""
ssh_user         = ""

```
è stato predisposto un file di esempio, per utiliuzarlo eseguire:
```bash
cd terraform && cp terraform.tfvars.example terraform.tfvars
```

Per eseguire è sufficente:
```bash
cd terraform && terraform init && terraform apply
```

## Configurazione
La configurazione dell'infrastruttura avviene tramite ansible.

Valorizare il file inventory.ini copiando dal file esempio:
```bash
cd ansible && cp inventory.ini.example inventory.ini
```
oppure:
```bash
[kube:children]
masters
slaves

[kube:vars]
ssh_key=

[masters]
master ansible_host= ansible_user= ansible_become=

[slaves]
slave-01 ansible_host= ansible_user= ansible_become=
slave-02 ansible_host= ansible_user= ansible_become=
```

Per eseguire il playbook è sufficente eseguire:
```bash
cd ansible && ansible-playbook -i inventory.ini main.yaml
```

Questo playbook è diviso in quattro sezioni:
- preparazione delle VM (prepare)
- Bootstrap del cluster utilizando kubeadm (bootstrap)
- Join dei nodi worker (join)
- Esecuzione di alcuni test per verificare lo stato del cluster (heath)

Ogni sezione ha un suo tag, in questo modo si può eseguire anche una singola sezione, per esempio la sezione di health:
```bash
ansible-playbook -i inventory.ini main.yaml --tags 'health'
```

### Test stato del cluster
Per verificare lo stato del cluster i test eseguiti sono:
- creare un namespace
- lanciare un benchmark per verificare la sicurezza

Il tool scelto è kube-bench, poiche come viene riportato [qui] (https://devopscube.com/kube-bench-guide/):

```
Kube-bench can help with the following. 
  Cluster hardening: Kube-bench automates the process of checking the cluster configuration as per the security guidelines outlined in CIS benchmarks.
  Policy Enforcement: Kube-bech checks for RBAC configuration to ensure the necessary least privileges are applied to service accounts, users, etc. it also checks for pod security standards and secret management.
  Network segmentation: Kube-bench checks for CNI and its support for network policy to ensure that network policies are defined for all namespaces.
```

## Deploy applicazione

L'applicazione da deployare è la [seguente] (https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)

## Risultati
Il provisioning con terraform è riuscito perfettamente.
L'installazione del cluster kubernetes invece non è stabile, sono stati utilizzate le seguenti versioni:
- Debian 11 (OS)
- Containerd (CRI)
- Flannel (CNI)
- Kubernetes (1.27)

Questo comporta che l'esito del playbook è randomico, cosi come non è possibile arrivare al deploy dell'applicazione.

## Pipeline per il lint
Sono state predisposte le pipeline per il lint di terraform e di ansible

## Fonti utilizate
[Documentazione terraform gcp provider] (https://registry.terraform.io/providers/hashicorp/google/latest/docs)
[Documentazione ansible] (https://docs.ansible.com/ansible/latest/)
[Playbook da cui mi sono ispirato] (https://buildvirtual.net/deploy-a-kubernetes-cluster-using-ansible/)
[Helm chart applicazione] (https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
[Ansible lint] (https://github.com/ansible/ansible-lint-action)
[Terraform lint] (https://github.com/marketplace/actions/terraform-lint)

