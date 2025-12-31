![Policy-Driven Network Segmentation](docs/images/readme-banner.png)

# Cloud Network Segmentation (Policy-Driven AWS Security)

![AWS](https://img.shields.io/badge/AWS-Architecture-orange?logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?logo=terraform&logoColor=white)
![Policy as Code](https://img.shields.io/badge/Policy%20as%20Code-Security-blue)
![Network Segmentation](https://img.shields.io/badge/Network%20Segmentation-Deny%20by%20Default-critical)
![MITRE ATT&CK](https://img.shields.io/badge/Threat%20Modeling-MITRE%20ATT%26CK-red)
![Status](https://img.shields.io/badge/Status-Active%20Development-success)

## Overview

This project is designed for cloud security engineers, platform engineers, and security architects who want to enforce network segmentation using policy rather than ad-hoc infrastructure rules.

This repository implements **policy-driven network segmentation in AWS**, using a clear separation between:

- **Security intent** (human-readable policy)
- **Automated validation and translation**
- **Infrastructure enforcement with Terraform**

Rather than hardcoding security group rules directly into Terraform, this project defines **allowed network flows as policy**, validates them against guardrails, and generates Terraform variables automatically. This approach mirrors how mature cloud security and platform teams manage segmentation in regulated and high-risk environments.


---

## Design Goals

- Enforce **deny-by-default** network segmentation  
- Make all allowed traffic **explicit, reviewable, and auditable**  
- Prevent insecure rules from ever reaching Terraform  
- Separate **what is allowed** from **how it is enforced**  
- Support incremental hardening without redesign  

## Non-Goals

This project intentionally does not attempt to:

- Provide intrusion detection or alerting
- Replace WAF, IDS/IPS, or runtime security tooling
- Enforce compliance mappings for specific regulatory frameworks

The focus is strictly on **preventive network segmentation and blast-radius reduction**.

---

## Architecture Summary

The environment is segmented into four logical tiers:

| Tier | Purpose |
|---|---|
| **DMZ** | Internet-facing edge tier (ALB, reverse proxy, WAF integration point) |
| **App** | Application workloads (EC2 / ECS) |
| **Data** | Datastores (RDS, caches) |
| **Endpoints** | VPC endpoints / PrivateLink tier |

Traffic is only allowed between tiers **explicitly defined in policy**.  
All other traffic is **implicitly denied**.

Internet traffic terminates at the **Application Load Balancer (ALB)** in the DMZ.  
The App and Data tiers are never directly exposed to the internet.

## Architecture Diagram (Logical)

flowchart TB
  Internet([Internet])

  DMZ["DMZ Tier<br/>- Application Load Balancer<br/>- Internet-facing entry point<br/><br/>SG: dmz-sg"]
  APP["App Tier<br/>- EC2 / ECS application workloads<br/><br/>SG: app-sg"]
  DATA["Data Tier<br/>- RDS / Datastores<br/><br/>SG: data-sg"]
  EP["Endpoints Tier<br/>- VPC Endpoints / PrivateLink<br/><br/>SG: endpoints-sg"]

  Internet -->|HTTPS 443<br/>(explicitly allowed by policy)| DMZ
  DMZ -->|HTTPS 443<br/>(policy-defined)| APP
  DMZ -->|HTTP 80<br/>(ALB health checks)| APP
  APP -->|DB 5432<br/>(explicit policy)| DATA


**Legend**

- Solid arrows represent **explicitly allowed network flows** defined in policy  
- Absence of an arrow implies **deny-by-default**  
- All east–west traffic is enforced using **security group to security group rules**  
- Internet ingress terminates at the **ALB in the DMZ** and is not modeled as SG-to-SG traffic  
- Health check traffic (HTTP 80) is treated as a **first-class policy exception**


**Figure: Policy-Driven Network Segmentation Architecture**

This architecture enforces deny-by-default network segmentation using policy as the single source of truth.  
Only flows explicitly defined in policy are permitted between tiers and are enforced as security group–to–security group rules.  
All other network paths are implicitly denied, reducing lateral movement and limiting blast radius.

---

## Policy-Driven Segmentation

### Single Source of Truth

All segmentation intent lives in:

```text
policy/segmentation-policy.yaml
```
This file defines:

- Tiers
- Allowed flows between tiers
- Approved protocols and ports
- Internet access restrictions
- Guardrails that prevent unsafe configurations

### Example (Simplified)

```yaml
flows:
  - name: dmz_to_app_https
    from: dmz
    to: app
    protocol: tcp
    ports: [443]

  - name: dmz_to_app_http
    from: dmz
    to: app
    protocol: tcp
    ports: [80]
    description: "ALB health checks"

## Guardrails and Validation

Before any infrastructure is generated, the policy is validated by automation:

- Only approved protocols are allowed
- Only approved ports are allowed
- Internet access is restricted to approved ports
- Direct internet → data access is blocked
- Invalid tiers or malformed rules fail fast

Invalid policies **do not generate Terraform.**

This prevents insecure changes from reaching AWS.

## Automation Flow
segmentation-policy.yaml
        ↓
validate + enforce guardrails
        ↓
generate_sg_rules.py
        ↓
policy.auto.tfvars.json
        ↓
Terraform security group modules

The automation **does not create infrastructure**.  
It only generates inputs that Terraform consumes.

---

## Infrastructure Enforcement

Terraform modules enforce segmentation using:

- One security group per tier  
- Security group-to-security group rules only  
- No CIDR-based east-west rules  
- No implicit allow rules  

Internet ingress is intentionally **not implemented** as SG-to-SG rules.  
It is enforced at the ALB layer (listener + ALB security group).

---

## ALB Health Checks and Security

ALB health checks require explicit allowance from the DMZ tier to the App tier on port **80**.

This rule is:

- Documented in policy  
- Validated by guardrails  
- Automatically generated  
- Enforced as SG-to-SG ingress  

If the policy rule is removed, health checks fail and targets become unhealthy.



## Repository Structure

.
├── policy/
│   └── segmentation-policy.yaml
│
├── automation/
│   └── generate_sg_rules.py
│
├── infra/
│   └── terraform/
│       ├── envs/
│       │   └── prod/
│       │       ├── main.tf
│       │       ├── variables.tf
│       │       └── policy.auto.tfvars.json
│       └── modules/
│           ├── security_groups/
│           ├── alb_dmz/
│           └── network_vpc/
│
└── docs/
    └── architecture.md

## How to Use

### 1. Update segmentation policy

Edit:

```bash
policy/segmentation-policy.yaml
```

### 2. Generate Terraform inputs

Run the policy automation script:

```bash
python automation/generate_sg_rules.py
```

This generates the Terraform variables file:

```bash
infra/terraform/envs/prod/policy.auto.tfvars.json
```

3. Apply infrastructure
```bash
cd infra/terraform/envs/prod
terraform init
terraform apply
```

## Why This Matters

This project demonstrates:

- Real-world cloud segmentation patterns  
- Policy-as-code concepts without vendor lock-in  
- Defensive guardrails that prevent misconfiguration  
- Clear separation of intent versus enforcement  
- Debugging across AWS, Terraform, and Python  
- Practical ALB and security group behavior  

This is the same architectural pattern used in regulated cloud environments,
security-focused platform teams, and large-scale AWS deployments.

---

## Future Enhancements (Planned)

- HTTPS-only backend traffic  
- VPC endpoint-only patching (no internet egress)  
- Policy diff and dry-run mode  
- CI validation of policy changes  
- Multi-environment support (dev / prod parity)  

---

## Security Framework Context (Informational)

This project is informed by established government and industry guidance, without claiming formal compliance.

This segmentation model aligns with Zero Trust principles such as explicit trust boundaries, least privilege network access, and denial of implicit east-west trust, without attempting to implement a full Zero Trust architecture.

### Architectural Alignment

The segmentation model reflects principles described in NSA and CISA cloud security guidance, including:

- Explicit separation of trust zones (DMZ, application, data)
- Deny-by-default network access between tiers
- Reduction of lateral movement through strict workload isolation
- Enforcement of controls at the infrastructure boundary

These references shaped the **design philosophy**, not prescriptive control mappings.

### Threat-Informed Design

From a MITRE ATT&CK perspective, this architecture reduces the impact of:

- Post-compromise lateral movement
- Over-permissive east-west network access
- Implicit trust between application tiers
- Abuse of internal network paths after initial access

ATT&CK is used here to inform **threat modeling and blast-radius reduction**, not to assert coverage or compliance.

**Outcome:**  
A practical, policy-driven segmentation model that improves containment, auditability, and operational clarity in AWS environments.

---
## Author

Nisha McDonnell  
Cloud Security Engineer

Designed and implemented as a policy-driven AWS network segmentation project
to demonstrate secure-by-default architecture, automated guardrails, and
real-world infrastructure enforcement.

## License

This project is licensed under the MIT License.



