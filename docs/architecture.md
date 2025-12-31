# Cloud Network Segmentation Architecture

## Goal

Demonstrate policy-driven microsegmentation in AWS using:
- Tiered VPC subnets
- Security group to security group rules generated from a policy file
- An internet-facing ALB in the DMZ tier
- An app instance in the app tier
- Optional data tier for database patterns

## Tiers

- DMZ: public edge tier (ALB lives here)
- App: private application workloads
- Data: private databases and caches
- Endpoints: private VPC endpoints for AWS services

### Internet ingress handling

Internet-facing traffic is terminated at the ALB in the DMZ tier.
Although internet → dmz flows are documented in the segmentation policy,
they are enforced via ALB listeners and the ALB security group, not via
security group to security group rules.

This avoids exposing application-tier security groups directly to the internet.


## Allowed flows

Flows are defined in policy/segmentation-policy.yaml and validated by automation/validate_policy.py.

Example flows:
- internet -> dmz: 443 (documented, implemented at ALB security group and listener)
- dmz -> app: 80 (ALB health checks)
- dmz -> app: 443 (application traffic if you later enable HTTPS backends)
- app -> data: 5432 (database access example)

## Why policy-driven

Policy-driven means:
- Humans write intent (flows)
- Automation enforces guardrails (protocols, ports)
- Terraform enforces implementation consistently

This reduces drift and makes reviews straightforward.

## Diagram

See docs/diagrams/segmentation-architecture.png
