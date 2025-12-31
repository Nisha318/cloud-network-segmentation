import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Missing dependency: pyyaml. Install with: pip install pyyaml")
    sys.exit(1)


REPO_ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = REPO_ROOT / "policy" / "segmentation-policy.yaml"
OUT_PATH = REPO_ROOT / "infra" / "terraform" / "envs" / "prod" / "policy.auto.tfvars.json"


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")
    sys.exit(1)


def load_policy(path: Path) -> dict:
    if not path.exists():
        fail(f"Policy file not found: {path}")
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        fail("Policy file did not parse into a dictionary.")
    return data


def validate_policy(policy: dict) -> None:
    if "tiers" not in policy or not isinstance(policy["tiers"], dict):
        fail("Policy must include 'tiers' as a map.")
    if "flows" not in policy or not isinstance(policy["flows"], list):
        fail("Policy must include 'flows' as a list.")

    guardrails = policy.get("guardrails", {})
    allowed_protocols = set(guardrails.get("allowed_protocols", ["tcp"]))
    allowed_ports = set(guardrails.get("allowed_ports", []))
    allowed_internet_ports = set(guardrails.get("allowed_internet_ports", [443]))

    tiers = set(policy["tiers"].keys())
    tiers.add("internet")  # special source only

    for f in policy["flows"]:
        for k in ["name", "from", "to", "protocol", "ports"]:
            if k not in f:
                fail(f"Flow missing '{k}': {f}")

        if f["protocol"] not in allowed_protocols:
            fail(f"Flow '{f['name']}' uses disallowed protocol: {f['protocol']}")

        if f["from"] not in tiers:
            fail(f"Flow '{f['name']}' uses unknown from tier: {f['from']}")
        if f["to"] not in tiers:
            fail(f"Flow '{f['name']}' uses unknown to tier: {f['to']}")

        if f["from"] == "internet" and f["to"] == "data":
            fail("Direct internet to data tier is not allowed.")

        ports = f["ports"]
        if not isinstance(ports, list) or not ports:
            fail(f"Flow '{f['name']}' ports must be a non-empty list.")

        for p in ports:
            if not isinstance(p, int):
                fail(f"Flow '{f['name']}' has a non-integer port: {p}")
            if p < 1 or p > 65535:
                fail(f"Flow '{f['name']}' has an invalid port: {p}")

            if allowed_ports and p not in allowed_ports:
                fail(f"Flow '{f['name']}' uses port not in allowed_ports: {p}")

            if f["from"] == "internet" and p not in allowed_internet_ports:
                fail(f"Internet flow '{f['name']}' uses non-approved internet port: {p}")


def generate_tfvars(policy: dict) -> dict:
    tiers = list(policy["tiers"].keys())
    rules = []

    for f in policy["flows"]:
    
    # Internet ingress is intentionally not implemented as SG-to-SG rules.
    # It must be enforced at the ALB (listener + ALB SG) or via WAF.
    # Policy still documents intent for audit and review.

        if f["from"] == "internet":
            # Terraform module enforces SG-to-SG rules only.
            # Internet ingress should be implemented later via ALB SG or NACL/WAF.
            # For now, we skip it and keep policy for documentation and metrics.
            continue

        for p in f["ports"]:
            rules.append({
                "name": f["name"],
                "from_tier": f["from"],
                "to_tier": f["to"],
                "protocol": f["protocol"],
                "from_port": p,
                "to_port": p,
                "desc": f.get("description", f"{f['from']} -> {f['to']}:{p}")
            })

    return {
        "policy_tiers": tiers,
        "policy_rules": rules
    }


def main() -> None:
    policy = load_policy(POLICY_PATH)
    validate_policy(policy)
    tfvars = generate_tfvars(policy)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(tfvars, indent=2), encoding="utf-8")
    print(f"Wrote: {OUT_PATH}")
    print(f"Tiers: {len(tfvars['policy_tiers'])}, Rules: {len(tfvars['policy_rules'])}")


if __name__ == "__main__":
    main()
