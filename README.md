## 👥 팀원 소개

본 프로젝트는 여러 팀원이 각자의 장비와 클라우드 리소스를 활용하여 하나의 인프라 환경을 구성하고 함께 학습합니다.

각 팀원의 역할과 GitHub 정보는 아래에서 확인할 수 있습니다.

<div align="center">
  <table>
    <tr>
      <td align="center" width="200px">
        <a href="https://github.com/YongwanJoo">
          <img src="https://github.com/YongwanJoo.png" width="150px" alt="주용완"/>
        </a><br />
        <br />
        <b>주용완</b><br />
        &nbsp;<br />
        <a href="https://github.com/YongwanJoo">
          <img src="https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=GitHub&logoColor=white" alt="GitHub"/>
        </a>
      </td>
      <td align="center" width="200px">
        <a href="https://github.com/Smallt0wn">
          <img src="https://github.com/Smallt0wn.png" width="150px" alt="정장우"/>
        </a><br />
        <br />
        <b>정장우</b><br />
        &nbsp;<br />
        <a href="https://github.com/Smallt0wn">
          <img src="https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=GitHub&logoColor=white" alt="GitHub"/>
        </a>
      </td>
      <td align="center" width="200px">
        <a href="https://github.com/llokr1">
          <img src="https://github.com/llokr1.png" width="150px" alt="홍진기"/>
        </a><br />
        <br />
        <b>홍진기</b><br />
        &nbsp;<br />
        <a href="https://github.com/llokr1">
          <img src="https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=GitHub&logoColor=white" alt="GitHub"/>
        </a>
      </td>
    </tr>
  </table>
</div>

---

## 🏗️ Infrastructure Architecture

본 프로젝트는 여러 대의 물리 장비와 OCI VM을 WireGuard VPN으로 연결하여 하나의 사설 네트워크를 구성하고, 그 위에 Kubernetes 및 OpenStack-Helm 환경을 구축합니다.

```text
                         Internet
                            │
                            ▼
                    ┌───────────────┐
                    │   WireGuard   │
                    │   VPN Server  │
                    └───────┬───────┘
                            │
                     10.0.0.0/24
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
        ▼                   ▼                    ▼
   Physical Nodes        Physical Nodes       OCI VM
        │                   │                    │
        │                   │              ┌─────┴─────┐
        │                   │              │ OCI #1~#3 │
        │                   │              └───────────┘
        │                   │
        ├── Mini PC
        ├── Mini PC
        ├── GRAM
        ├── Desktop
        └── Mini PC
              │
              ▼
        Kubernetes Cluster
              │
              ├── Control Plane
              │
              └── Worker Nodes
                    │
                    ▼
              Helm
                    │
                    ▼
             OpenStack-Helm
                    │
        ┌───────────┼────────────┐
        ▼           ▼            ▼
     Keystone      Nova       Neutron
        │           │            │
        └───────────┼────────────┘
                    │
             Other Services
```

### 🌐 Network

모든 노드는 WireGuard를 통해 사설 네트워크로 연결합니다.

| 항목              | 구성            |
| --------------- | ------------- |
| VPN             | WireGuard     |
| Private Network | `10.0.0.0/24` |
| Node Count      | 8             |
| Physical Nodes  | 5             |
| OCI VM          | 3             |

> 실제 Public IP 및 WireGuard 인증 정보는 보안상의 이유로 Repository에 기록하지 않습니다.

---

## 🖥️ Hardware Nodes

현재 프로젝트에서 사용하는 전체 인프라는 물리 장비와 OCI VM으로 구성됩니다.

### Physical Nodes

| Node      | 소유자 | CPU                       |  RAM |   Storage | 용도                       | Private IP  |
| --------- | --- | ------------------------- | ---: | --------: | ------------------------ | ----------- |
| Mini PC   | 진기  | AMD Ryzen 7               | 16GB | SSD 512GB | -                        | `10.0.0.1`  |
| Mini PC   | 장우  | AMD Ryzen 7               | 16GB | SSD 512GB | Kubernetes Control Plane | `10.0.0.7`  |
| GRAM      | 장우  | Intel Core i5             | 16GB | SSD 512GB | -                        | `10.0.0.6`  |
| Desktop 1 | 진기  | Intel Core i3             |  8GB |   HDD 1TB | -                        | `10.0.0.5`  |
| Mini PC   | 용완  | AMD Ryzen 7 H255 (8C/12T) | 30GB |   SSD 1TB | -                        | `10.0.0.10` |

### OCI Nodes

| Node      | 소유자 | CPU         | RAM | Storage | Private IP  |
| --------- | --- | ----------- | --: | ------: | ----------- |
| OCI VM #1 | 장우  | vCPU 1 Core | 1GB |   100GB | `10.0.0.8`  |
| OCI VM #2 | 장우  | vCPU 1 Core | 1GB |   100GB | `10.0.0.9`  |
| OCI VM #3 | 용완  | vCPU 1 Core | 1GB |   100GB | `10.0.0.11` |

### Resource Summary

현재 구성 기준으로 전체 인프라는 다음과 같은 규모입니다.

```text
Physical Nodes : 5
OCI VM         : 3
Total Nodes    : 8

CPU / Memory
├── Physical : 56GB RAM
└── OCI      : 3GB RAM
                 ↓
          Total 59GB RAM
```

> 실제 사용 가능한 CPU 및 메모리는 VM 할당량, 운영체제, Kubernetes 시스템 Pod 등의 리소스 사용량에 따라 달라집니다.

---

## ☸️ Kubernetes Architecture

물리 노드와 OCI VM을 WireGuard 네트워크로 연결한 뒤 Kubernetes 클러스터를 구성합니다.

```text
                 Kubernetes Cluster
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
        Control Plane          Worker Nodes
              │                     │
              │              ┌──────┼──────┐
              │              │      │      │
              ▼              ▼      ▼      ▼
         API Server         Node   Node   Node
              │
        ┌─────┼─────┐
        ▼     ▼     ▼
      etcd  Scheduler
            Controller
```

Kubernetes는 단순히 컨테이너를 실행하는 용도가 아니라,

* Container Scheduling
* Service Discovery
* Networking
* Resource Management
* Self-healing
* Declarative Deployment

등을 담당합니다.

---

## ☁️ OpenStack-Helm Architecture

Kubernetes 클러스터가 구성되면 Helm을 이용하여 OpenStack-Helm을 배포합니다.

```text
                Kubernetes
                    │
                    ▼
                  Helm
                    │
                    ▼
             OpenStack-Helm
                    │
       ┌────────────┼────────────┐
       │            │            │
       ▼            ▼            ▼
   Keystone       Glance        Nova
       │                           │
       │                           ▼
       │                        Neutron
       │                           │
       └────────────┬──────────────┘
                    │
              OpenStack Cloud
```

OpenStack-Helm에서는 OpenStack 서비스를 Kubernetes의 Pod, Deployment, StatefulSet 등의 리소스로 배포하고 관리합니다.

이를 통해 Kubernetes의 Container Orchestration 기능과 OpenStack의 Cloud Infrastructure 기능을 함께 학습합니다.

---

## 📊 Node Specification

전체 노드 구성은 구축 상황에 따라 변경될 수 있으며, 실제 Kubernetes 역할은 별도로 문서화합니다.

```text
Node
│
├── Physical Node
│   ├── Mini PC
│   ├── Mini PC
│   ├── GRAM
│   ├── Desktop
│   └── Mini PC
│
└── Cloud Node
    ├── OCI VM #1
    ├── OCI VM #2
    └── OCI VM #3
```

각 노드의 실제 역할과 Kubernetes Label/Taint 등의 설정은 구축 과정에서 업데이트합니다.

---

## 🔐 Security

Repository에는 다음 정보를 포함하지 않습니다.

* WireGuard Private Key
* WireGuard Peer 설정의 Secret
* 실제 인증 정보
* SSH Private Key
* Cloud API Key
* 실제 운영 환경의 민감한 정보

필요한 설정은 예시 파일을 제공하고 실제 값은 별도로 관리합니다.

예:

```text
.env.example
wg0.conf.example
inventory.example
```
