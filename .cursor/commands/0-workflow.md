# WORKFLOW - Complete workflow overview

## Purpose

Provides an overview of the complete AI Development Notes workflow and all available phases.

## Workflow Phases

The workflow follows these phases, all documented in **ONE document** (`AIN - [FEATURE_NAME].md`):

1. **C: CONCEPT** - Discuss ideas without generating code

   - Use `/1-concept` command

2. **D: DESIGN** - Design detailed solution

   - Use `/2-design` command

3. **P: PLAN** - Create implementation plan

   - Use `/3-plan` command

4. **V: REVIEW** - Review and validate the implementation plan

   - Use `/4-review` command

5. **B: BRANCH** - Create Git branches for required repos

   - Use `/5-branch` command

6. **I: IMPLEMENT** - Execute the plan

   - Use `/6-implement` command

7. **L: LINT** - Check and fix linting issues

   - Use `/7-lint` command

8. **T: TEST** - Run tests

   - Use `/8-test` command

9. **M: DOCUMENT** - Document the solution

   - Use `/9-document` command

10. **R: PULL REQUEST** - Create PRs for all repos
    - Use `/10-pull-request` command

## Getting Started

1. **Copy the template**: `.github/docs/AI/AIN - WORKFLOW_TEMPLATE.md`
2. **Rename to**: `AIN - [TASK_NAME].md`
3. **Start with CONCEPT phase**: Use `/1-concept` command
4. **Progress through phases** in order (use numbered commands: `/1-concept`, `/2-design`, etc.)
5. **All phases go in the SAME document** - do NOT create separate files

## Important Principles

- **ONE document per task** - All phases in a single file
- **Follow the template structure** - Each phase is a section
- **Reference component rules** - Check `.cursor/rules/[component].mdc`
- **Follow coding standards** - See `.github/docs/AI/AI-RULES.md`
- **Run ESLint** - Mandatory before declaring work "done"

## Related Files

- **Template**: `.github/docs/AI/AIN - WORKFLOW_TEMPLATE.md`
- **AI Rules**: `.github/docs/AI/AI-RULES.md`
- **Workflow Reference**: `.cursor/context/workflow-reference.md`
- **Component Rules**: `.cursor/rules/*.mdc`

## Quick Reference

- `/1-concept` - Start discussing ideas
- `/2-design` - Design the solution
- `/3-plan` - Create implementation plan
- `/4-review` - Review the plan
- `/5-branch` - Create Git branches
- `/6-implement` - Execute implementation
- `/7-lint` - Fix linting issues
- `/8-test` - Run tests
- `/9-document` - Document solution
- `/10-pull-request` - Create PRs
