# 0001 Segmentation model and policy-driven rules

Date: 2025-12-30  
Status: Accepted

## Context

We need a repeatable way to implement network segmentation in AWS that is:
- Understandable by humans (security, engineering, audit)
- Enforceable as code (Terraform)
- Safe by default (deny-by-default posture with explicit exceptions)
- Easy to change without hand-editing many security group rules

Security group rules are easy to get wrong and hard to review at scale when written manually.

## Decision

We will use a tier-based segmentation model with explicit flows:
- Tiers: dmz, app, data, endpoints
- Allowed communications are defined as flows in a single policy file (YAML)
- A generator converts flows into Terraform variables (JSON tfvars)
- Terraform applies security group to security group rules for tier-to-tier access

Internet ingress is documented in policy but implemented at the ALB (dmz) layer, not as SG-to-SG rules.

## Consequences

Positive:
- Single source of truth for segmentation intent (policy YAML)
- Guardrails prevent unsafe ports and protocols from entering the plan
- Easier reviews and diffs, because policy changes are small and readable
- Repeatable across environments (dev, prod)

Tradeoffs:
- Extra moving part (policy generator) to learn and run
- Requires discipline to keep policy and Terraform in sync
- Some flows are implemented outside SG-to-SG rules (ALB listener rules, WAF)

## Implementation notes

- Policy file: policy/segmentation-policy.yaml
- Validation script: automation/validate_policy.py
- Generator script: automation/generate_sg_rules.py
- Generated tfvars: infra/terraform/envs/<env>/policy.auto.tfvars.json
