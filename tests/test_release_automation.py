import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]


def workflow_step(workflow_name, job_name, step_name):
    workflow = json.loads(
        subprocess.check_output(
            [
                "yq",
                "-o=json",
                ".",
                str(REPOSITORY / ".github/workflows" / workflow_name),
            ],
            text=True,
        )
    )
    return next(
        step["run"]
        for step in workflow["jobs"][job_name]["steps"]
        if step.get("name") == step_name
    )


class ReleaseAutomationTests(unittest.TestCase):
    def run_script(self, script, environment, prefix=""):
        with tempfile.TemporaryDirectory() as temporary_directory:
            return subprocess.run(
                ["bash", "-euo", "pipefail", "-c", prefix + script],
                env={
                    **os.environ,
                    "RUNNER_TEMP": temporary_directory,
                    **environment,
                },
                capture_output=True,
                text=True,
            )

    def test_app_token_can_inspect_protection_but_cannot_change_it(self):
        permissions = json.loads(
            subprocess.check_output(
                [
                    "yq",
                    "-o=json",
                    '.jobs.update.steps[] | select(.id == "app-token") | .with',
                    str(REPOSITORY / ".github/workflows/update-sources.yaml"),
                ],
                text=True,
            )
        )
        self.assertEqual(
            permissions.get("permission-administration"),
            "read",
            "The update App must be able to inspect branch protection without "
            f"being able to weaken it; its token request was {permissions}.",
        )

    def test_credentials_require_a_complete_app_or_explicit_update_token(self):
        script = workflow_step(
            "update-sources.yaml", "update", "Require update credentials"
        )
        for app_id, private_key, token, expected_success in [
            ("", "", "", False),
            ("test-app", "", "", False),
            ("", "test-key", "test-token", False),
            ("test-app", "test-key", "", True),
            ("", "", "test-token", True),
        ]:
            with self.subTest(app_id=app_id, has_token=bool(token)):
                result = self.run_script(
                    script,
                    {
                        "APP_ID": app_id,
                        "APP_PRIVATE_KEY": private_key,
                        "UPDATE_TOKEN": token,
                    },
                )
                self.assertEqual(
                    result.returncode == 0,
                    expected_success,
                    f"Incomplete credentials must fail closed; got {result}.",
                )

    def test_auto_merge_requires_both_checks_and_enforced_branch_protection(self):
        script = workflow_step(
            "update-sources.yaml", "update", "Verify required merge gates"
        )
        protected_rule = {
            "requiresStatusChecks": True,
            "isAdminEnforced": True,
            "requiredStatusCheckContexts": ["nix flake check", "sources-only"],
        }
        for rule, auto_merge, expected_success in [
            (protected_rule, True, True),
            (None, True, False),
            ({**protected_rule, "isAdminEnforced": False}, True, False),
            ({**protected_rule, "requiredStatusCheckContexts": []}, True, False),
            (protected_rule, False, False),
        ]:
            with self.subTest(rule=rule, auto_merge=auto_merge):
                response = {
                    "data": {
                        "repository": {
                            "autoMergeAllowed": auto_merge,
                            "squashMergeAllowed": True,
                            "ref": {"branchProtectionRule": rule},
                        }
                    }
                }
                result = self.run_script(
                    script,
                    {
                        "GITHUB_REPOSITORY": "test/repository",
                        "TEST_RESPONSE": json.dumps(response),
                    },
                    'gh() { printf "%s" "$TEST_RESPONSE"; }\n',
                )
                self.assertEqual(
                    result.returncode == 0,
                    expected_success,
                    f"Auto-merge must require both enforced checks; got {result}.",
                )

    def test_source_guard_accepts_only_exact_pin_paths_for_update_branch(self):
        script = workflow_step(
            "guard-update-paths.yaml",
            "sources-only",
            "Restrict automated updates to source pins",
        )
        for paths, head_branch, expected_success in [
            (
                ["_sources/generated.nix", "_sources/generated.json"],
                "automated/update-sources",
                True,
            ),
            (["flake.nix"], "automated/update-sources", False),
            (["_sources/unexpected.sh"], "automated/update-sources", False),
            (["_sources/generated.nix\nflake.nix"], "automated/update-sources", False),
            (["flake.nix"], "human-change", True),
        ]:
            with self.subTest(paths=paths, head_branch=head_branch):
                with tempfile.NamedTemporaryFile() as changed_paths:
                    changed_paths.write(
                        b"".join(path.encode() + b"\0" for path in paths)
                    )
                    changed_paths.flush()
                    result = self.run_script(
                        script,
                        {
                            "UPDATE_BRANCH": "automated/update-sources",
                            "HEAD_BRANCH": head_branch,
                            "BASE_SHA": "base",
                            "HEAD_SHA": "head",
                            "TEST_PATHS": changed_paths.name,
                        },
                        'git() { cat "$TEST_PATHS"; }\n',
                    )
                self.assertEqual(
                    result.returncode == 0,
                    expected_success,
                    f"Only exact pin paths may pass automated PRs; got {result}.",
                )


if __name__ == "__main__":
    unittest.main()
