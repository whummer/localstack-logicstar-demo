import json
from pathlib import Path
from typing import Any


def _load_policy(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _normalize_actions(action_field: Any) -> set[str]:
    if action_field is None:
        return set()
    if isinstance(action_field, str):
        return {action_field.lower()}
    return {a.lower() for a in action_field}


def test_submit_quiz_policy_includes_sqs_permissions() -> None:
    policy_path = Path("configurations/submit_quiz_policy.json")
    assert policy_path.exists(), "Submit quiz policy JSON not found."

    policy = _load_policy(policy_path)
    statements = policy.get("Statement", [])

    required_queue_arn = "arn:aws:sqs:us-east-1:000000000000:QuizSubmissionQueue"

    has_get_queue_url = False
    has_send_message = False

    for stmt in statements:
        if stmt.get("Effect") != "Allow":
            continue

        actions = _normalize_actions(stmt.get("Action", []))
        resource = stmt.get("Resource")

        resources = resource if isinstance(resource, list) else [resource]
        resources = [r for r in resources if isinstance(r, str)]

        if "sqs:getqueueurl" in actions:
            if any(r in (required_queue_arn, "*") for r in resources):
                has_get_queue_url = True

        if "sqs:sendmessage" in actions:
            if any(r in (required_queue_arn, "*") for r in resources):
                has_send_message = True

    assert has_get_queue_url, (
        "Policy must allow sqs:GetQueueUrl on the QuizSubmissionQueue (or '*')."
    )
    assert has_send_message, (
        "Policy must allow sqs:SendMessage on the QuizSubmissionQueue (or '*')."
    )
