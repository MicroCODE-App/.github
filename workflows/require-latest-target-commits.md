# Require Latest Target Commits CI Workflow

## Overview

This document covers the `require-latest-target-commits.yml` GitHub Actions workflow that ensures PR branches include all commits from their target branch before merging. It includes both automated testing via a Node.js script and manual test procedures.

---

## Automated Testing

### JavaScript Test Script

A Node.js script (`bin/test.workflow.js`) automatically tests the workflow logic locally by simulating various PR scenarios.

#### Why JavaScript?

JavaScript/Node.js is perfect for testing GitHub Actions workflows because:
- ✅ **Cross-platform** - Works on Windows, macOS, and Linux
- ✅ **No shell dependencies** - No need for bash or PowerShell
- ✅ **Easy integration** - Can be added to npm scripts or CI/CD pipelines
- ✅ **Familiar syntax** - Uses standard Node.js APIs (`child_process`, `fs`, `path`)
- ✅ **Module exports** - Can be imported and used programmatically

#### Quick Start

```bash
# Using npm script (recommended)
npm run test:workflow

# Or directly with node
node bin/test.workflow.js

# With custom test directory
TEST_REPO_DIR=/custom/path node bin/test.workflow.js

# Help
node bin/test.workflow.js --help
```

#### What It Tests

The script creates a temporary test repository and runs 7 automated test cases:

1. **TC-1:** PR branch up-to-date with target branch ✓
2. **TC-2:** PR branch missing commits from target branch ✓
3. **TC-3:** Multiple missing commits ✓
4. **TC-4:** PR branch ahead of target (should pass) ✓
5. **TC-5:** PR to `develop` branch ✓
6. **TC-6:** PR to release branch (`release/b*`) ✓
7. **TC-7:** Empty branch edge case ✓

#### How It Works

**Setup Phase:**
- Creates a temporary test repository in your system temp directory
- Initializes git with test branches:
  - `main` (PRODUCTION) - 3 commits
  - `develop` (ALPHA/FEATURE) - 2 commits
  - `release/b0.2.0` (BETA) - 1 commit

**Test Execution:**
Each test case:
- Creates a test branch from a target branch
- Simulates PR scenarios (missing commits, ahead commits, etc.)
- Runs the core workflow logic: `git log --oneline HEAD..target --branches`
- Validates the results match expected behavior

**Cleanup:**
- Automatically removes the temporary test repository
- Restores original working directory

#### Core Logic

The script simulates the exact workflow logic:

```javascript
// This matches the workflow's git log command
git log --oneline HEAD..origin/targetBranch --branches
```

It checks for commits in the target branch that are not present in the PR branch, exactly like the GitHub Actions workflow does.

#### Programmatic Usage

You can also import and use the functions programmatically:

```javascript
const { runAllTests, checkMissingCommits } = require('./bin/test.workflow.js');

// Run all tests
const exitCode = runAllTests();

// Or test a specific scenario
const hasMissingCommits = checkMissingCommits('feature-branch', 'main');
```

#### Expected Output

```
Setting up test repository...
Test repository initialized

========================================
Running Automated Tests
========================================

=== TC-1: PR Branch Up-to-Date ===
Checking for commits in 'main' not present in 'test/require-latest-tc1'...
PASS: Branch 'test/require-latest-tc1' includes all commits from 'main'
✓ TC-1 PASSED

=== TC-2: PR Branch Missing Commits ===
Checking for commits in 'main' not present in 'test/require-latest-tc2'...
FAIL: Branch 'test/require-latest-tc2' is missing 1 commit(s) from 'main'
Missing commits:
abc1234 New commit in main after branch
✓ TC-2 PASSED (correctly detected missing commits)

...

========================================
Tests Passed: 7
Tests Failed: 0
========================================

All tests passed! ✓
```

#### Integration Examples

**GitHub Actions CI:**

Add to your `.github/workflows/ci.yml`:

```yaml
name: Test Workflow Logic

on:
  pull_request:
    paths:
      - '.github/workflows/require-latest-target-commits.yml'
  workflow_dispatch:

jobs:
  test-workflow:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm run test:workflow
```

**Pre-commit Hook:**

Add to `.husky/pre-commit` or similar:

```bash
#!/bin/sh
npm run test:workflow
```

**Local Development:**

Run before committing workflow changes:

```bash
npm run test:workflow
```

---

## Manual Test Plan

### Test Environment Setup

#### Prerequisites
- Access to a test repository (or use this repo's test branches)
- Ability to create branches and pull requests
- GitHub Actions enabled on the repository
- Permissions to add labels to PRs

#### Test Branches Structure
```
main (PRODUCTION)
├── commit A
├── commit B
└── commit C

develop (ALPHA/FEATURE)
├── commit D
└── commit E

release/b0.2.0 (BETA)
└── commit F

feature/test-branch (for testing)
```

---

## Test Cases

### TC-1: PR Branch Up-to-Date with Target Branch
**Objective:** Verify workflow passes when PR branch includes all target branch commits.

**Steps:**
1. Create branch `feature/test-updated` from `main`
2. Add commit to `feature/test-updated`
3. Create PR: `feature/test-updated` → `main`
4. Ensure `main` has no new commits since branch creation

**Expected Result:**
- ✅ Workflow passes
- ✅ Output: `::notice::Branch includes all commits from 'main'. Safe to merge.`
- ✅ No errors

**Validation:**
- Check GitHub Actions run shows green checkmark
- Verify log output contains success notice

---

### TC-2: PR Branch Missing Commits from Target Branch
**Objective:** Verify workflow fails when PR branch is missing commits from target.

**Steps:**
1. Create branch `feature/test-outdated` from `main` at commit A
2. Add new commit B to `main` (after branch creation)
3. Create PR: `feature/test-outdated` → `main`

**Expected Result:**
- ❌ Workflow fails with exit code 1
- ❌ Error message: `This branch is missing X commit(s) from 'main'.`
- ❌ Lists missing commits
- ❌ Provides fix instructions

**Validation:**
- Check GitHub Actions run shows red X
- Verify error message includes commit count
- Verify missing commits are listed
- Verify fix instructions are present

---

### TC-3: Bypass with `allow-divergence` Label
**Objective:** Verify workflow bypasses check when label is present.

**Steps:**
1. Create branch `feature/test-bypass` from `main` at commit A
2. Add new commit B to `main` (after branch creation)
3. Create PR: `feature/test-bypass` → `main`
4. Add label `allow-divergence` to PR

**Expected Result:**
- ✅ Workflow passes (bypasses check)
- ✅ Warning: `Bypass enabled via 'allow-divergence' label. Skipping target-commit enforcement.`
- ✅ Verification step is skipped

**Validation:**
- Check GitHub Actions run shows yellow warning or passes
- Verify bypass notice appears in logs
- Verify verification step shows as skipped

---

### TC-4: PR to `develop` Branch
**Objective:** Verify workflow triggers and works for `develop` target branch.

**Steps:**
1. Create branch `feature/test-develop` from `develop`
2. Add commit to `develop` after branch creation
3. Create PR: `feature/test-develop` → `develop`

**Expected Result:**
- ✅ Workflow triggers
- ❌ Workflow fails (if commits missing) or ✅ passes (if up-to-date)
- ✅ Uses correct branch name in messages

**Validation:**
- Verify workflow runs for PR to `develop`
- Check branch name appears correctly in output

---

### TC-5: PR to Release Branch (`release/b*`)
**Objective:** Verify workflow triggers for release branch pattern.

**Steps:**
1. Create branch `feature/test-release` from `release/b0.2.0`
2. Add commit to `release/b0.2.0` after branch creation
3. Create PR: `feature/test-release` → `release/b0.2.0`

**Expected Result:**
- ✅ Workflow triggers
- ❌ Workflow fails (if commits missing) or ✅ passes (if up-to-date)
- ✅ Handles release branch naming correctly

**Validation:**
- Verify workflow runs for PR to release branch
- Check branch name appears correctly in output

---

### TC-6: Multiple Missing Commits
**Objective:** Verify workflow correctly counts and lists multiple missing commits.

**Steps:**
1. Create branch `feature/test-multiple` from `main` at commit A
2. Add commits B, C, D to `main` (after branch creation)
3. Create PR: `feature/test-multiple` → `main`

**Expected Result:**
- ❌ Workflow fails
- ❌ Error shows: `missing 3 commit(s)`
- ❌ Lists all 3 missing commits
- ✅ Commit count matches actual missing commits

**Validation:**
- Verify commit count is accurate
- Verify all missing commits are listed
- Verify no duplicate commits in list

---

### TC-7: Empty PR Branch (No Commits)
**Objective:** Verify workflow handles edge case of empty branch.

**Steps:**
1. Create empty branch `feature/test-empty` from `main`
2. Create PR: `feature/test-empty` → `main`

**Expected Result:**
- ✅ Workflow passes (if branch equals target)
- ✅ Or fails appropriately if target has commits

**Validation:**
- Verify workflow doesn't crash
- Verify appropriate pass/fail based on state

---

### TC-8: PR Branch Ahead of Target
**Objective:** Verify workflow passes when PR branch is ahead (has extra commits).

**Steps:**
1. Create branch `feature/test-ahead` from `main`
2. Add commits to `feature/test-ahead` (A, B, C)
3. Ensure `main` has no new commits
4. Create PR: `feature/test-ahead` → `main`

**Expected Result:**
- ✅ Workflow passes
- ✅ No errors (being ahead is OK)

**Validation:**
- Verify workflow passes
- Verify no false positives

---

### TC-9: Bypass Label Case Sensitivity
**Objective:** Verify bypass label matching is case-sensitive.

**Steps:**
1. Create branch `feature/test-label-case` from `main` at commit A
2. Add commit B to `main`
3. Create PR: `feature/test-label-case` → `main`
4. Add label `Allow-Divergence` (different case)

**Expected Result:**
- ❌ Workflow fails (label doesn't match)
- ❌ No bypass occurs

**Validation:**
- Verify exact label match required
- Verify case-sensitive matching

---

### TC-10: Git Fetch Strategy
**Objective:** Verify `git fetch --all --prune --tags` works correctly.

**Steps:**
1. Create PR with stale remote refs scenario
2. Monitor workflow logs for fetch step

**Expected Result:**
- ✅ Fetch step completes successfully
- ✅ All refs fetched
- ✅ Stale refs pruned
- ✅ Tags included

**Validation:**
- Check logs show successful fetch
- Verify no fetch errors

---

### TC-11: Workflow Trigger on Correct Events
**Objective:** Verify workflow only triggers on PR events to specified branches.

**Steps:**
1. Create PR to `main` → ✅ Should trigger
2. Create PR to `develop` → ✅ Should trigger
3. Create PR to `release/b1.0.0` → ✅ Should trigger
4. Create PR to `other-branch` → ❌ Should NOT trigger
5. Push directly to `main` → ❌ Should NOT trigger

**Expected Result:**
- Workflow triggers only for PRs to `main`, `develop`, or `release/b*`
- No triggers for other events or branches

**Validation:**
- Check workflow run history
- Verify correct trigger behavior

---

### TC-12: Error Message Formatting
**Objective:** Verify error messages are clear and actionable.

**Steps:**
1. Create PR missing commits
2. Review error output

**Expected Result:**
- ✅ Clear error message with commit count
- ✅ Missing commits listed
- ✅ Actionable fix instructions
- ✅ Proper formatting (blank lines, indentation)

**Validation:**
- Verify readability of error messages
- Verify fix instructions are copy-pasteable

---

## Regression Tests

### RT-1: Workflow Stability
- Run workflow 10 times on same PR
- Verify consistent results

### RT-2: Concurrent PRs
- Create multiple PRs simultaneously
- Verify all workflows complete successfully

### RT-3: Large Number of Missing Commits
- Test with 50+ missing commits
- Verify performance and output readability

---

## Performance Tests

### PT-1: Large Repository
- Test on repository with 10,000+ commits
- Verify workflow completes in reasonable time (< 2 minutes)

### PT-2: Deep Branch History
- Test with branch diverged 100+ commits ago
- Verify git log performance

---

## Security Tests

### ST-1: Label Injection
- Attempt to inject malicious content via label names
- Verify no code execution vulnerabilities

### ST-2: Branch Name Injection
- Test with special characters in branch names
- Verify safe handling

---

## Test Execution Checklist

- [ ] TC-1: PR Branch Up-to-Date
- [ ] TC-2: PR Branch Missing Commits
- [ ] TC-3: Bypass with Label
- [ ] TC-4: PR to develop Branch
- [ ] TC-5: PR to Release Branch
- [ ] TC-6: Multiple Missing Commits
- [ ] TC-7: Empty PR Branch
- [ ] TC-8: PR Branch Ahead of Target
- [ ] TC-9: Bypass Label Case Sensitivity
- [ ] TC-10: Git Fetch Strategy
- [ ] TC-11: Workflow Trigger Events
- [ ] TC-12: Error Message Formatting
- [ ] RT-1: Workflow Stability
- [ ] RT-2: Concurrent PRs
- [ ] RT-3: Large Number of Missing Commits
- [ ] PT-1: Large Repository
- [ ] PT-2: Deep Branch History
- [ ] ST-1: Label Injection
- [ ] ST-2: Branch Name Injection

---

## Test Data

### Sample Commits for Testing
```bash
# Create test commits
git commit --allow-empty -m "Test commit A"
git commit --allow-empty -m "Test commit B"
git commit --allow-empty -m "Test commit C"
```

### Sample Branch Creation
```bash
# Create test branch from main
git checkout main
git checkout -b feature/test-branch

# Create PR scenario with missing commits
git checkout main
git commit --allow-empty -m "New commit in main"
git push origin main
```

---

## Requirements

- **Node.js** 22+ (for automated testing script)
- **Git** installed and available in PATH
- Write permissions to create temporary directories (for automated tests)
- GitHub Actions enabled on repository (for manual testing)

---

## Troubleshooting

### Git Not Found
```bash
# Verify git is installed
git --version

# On Windows, ensure git is in PATH
# On macOS/Linux, install via package manager
```

### Permission Errors (Automated Tests)
```bash
# Check temp directory permissions
ls -la $(node -e "console.log(require('os').tmpdir())")

# Or set custom directory
TEST_REPO_DIR=/tmp/my-test-repo node bin/test.workflow.js
```

### Test Failures
- Check that git commands are working: `git --version`
- Verify you have write permissions in temp directory
- Ensure no other process is using the test repository directory
- For manual tests, verify GitHub Actions are enabled and have proper permissions

---

## Success Criteria

✅ All test cases pass
✅ No false positives or negatives
✅ Error messages are clear and actionable
✅ Bypass mechanism works as intended
✅ Performance is acceptable
✅ Security concerns addressed

---

## Related Files

- `require-latest-target-commits.yml` - The workflow being tested
- `bin/test.workflow.js` - Automated test script
- `package.json` - Contains `test:workflow` script

---

## Notes

- Automated tests use `child_process.execSync` to run git commands
- Test repository is created in system temp directory by default
- All git commands are run with proper error handling
- The automated script cleans up automatically, even on errors
- **Safety**: The script validates test directory location and prevents accidental deletion of important directories
- **Isolation**: Branches are reset between test cases to prevent interference
- **Local Testing**: The test script uses `git log HEAD..target` (without `--branches`) because local testing without remotes would include commits from all branches with `--branches`
- For manual testing, use a dedicated test repository or feature flags
- Document any deviations from expected behavior
- Update test plan if workflow changes

---

## Related Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Git Log Documentation](https://git-scm.com/docs/git-log)
