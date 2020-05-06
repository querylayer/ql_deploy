# QL Deploy
Script can install QueryLayer ViewFinder on RHEL7 and Ubunut 18.04 . It does the following,
- Install Docker and Docker Compose.
- Download our recommended Docker Compose configuration and create initial configuration.
- Start everything.

## Installation
For RHEL 7 the below repositories must be enabled for docker installation`

```
sudo subscription-manager repos --enable=rhel-7-server-rpms  --enable=rhel-7-server-extras-rpms  --enable=rhel-7-server-optional-rpms
sudo yum -y install git
```
Install QueryLayer ViewFinder

```
$ git clone https://github.com/querylayer/ql_deploy.git
$ cd ql_deploy/
$ ./setup.sh
```
