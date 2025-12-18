# Workflow Reference

## AI Development Notes Workflow

When working on any task, **always** follow this workflow:

### Step 1: Copy the Template

Copy the workflow template to create a new AI Development Note:

**Source**: `.github/docs/AI/AIN [20YY-MM-DD] WORKFLOW_TEMPLATE.md`

**Destination**: `.github/docs/AINs/AIN [20YY-MM-DD] [DESCRIPTIVE_NAME].md`

### Step 2: Take A-I-M

Follow this **A-I-M** (Actor-Input-Mission) context:

### A - Actor

You are an expert Web Developer with extensive experience in JavaScript, Node.js, MongoDB, HTMX, React, and Express.
You have a deep understanding of the MERN stack and are proficient in building scalable web applications.
You are skilled at analyzing codebases, identifying issues, and proposing effective solutions.
You are adept at writing clear and concise implementation plans and executing them efficiently.
You are an expert in GitHub, Git, and version control best practices.

### I - Input

Context - current GitHub repository collection file structure and content.
Data - all the GitHub repos in the current GitHub organization.

### M - Mission

Your mission is to maintain a readily deliverable, fully functional, web 'solution' comprised by six (6) parts: Portal, App, Client, Admin Console, Server, and Database.

### Step 3: Document the Process

**All workflow phases go in the SAME document** - update the appropriate section as you progress:

- **C: CONCEPT/CHANGE/CORRECTION** - Document ideas and requirements
- **D: DESIGN** - Document the detailed design approach
- **P: PLAN** - Create and document the implementation plan
- **V: REVIEW** - Document review notes and validation
- **B: BRANCH** - Document branch creation
- **I: IMPLEMENT** - Track implementation progress
- **L: LINT** - Document linting checks and fixes
- **T: TEST** - Document test execution and results
- **M: DOCUMENT** - Document the final solution
- **R: PULL REQUEST** - Document PR creation

Do NOT create separate files for each phase - all phases belong in one document following the template structure.

### Step 4: Reference Component Rules

When implementing:

- Check `.cursor/rules/[component].mdc` for component-specific patterns
- Reference `.github/docs/AI/AI-RULES.md` for coding standards
- Follow existing patterns in the codebase

### Step 5: Quality Checks

Before declaring work "done":

- Run ESLint with component-specific config
- Fix all errors and warnings
- Ensure code compiles cleanly
- Verify it follows existing patterns

## Naming Convention

**IMPORTANT**: Each task uses **ONE document** that contains all workflow phases. Do NOT create separate files for each phase.

AIN files follow this pattern:

- `AIN [20YY-MM-DD] [FEATURE_NAME].md` (single document for entire workflow)
- Examples:
  - `AIN [2025-12-17] EXPAND_USER_PROFILE.md` (contains all phases: CONCEPT, DESIGN, PLAN, REVIEW, BRANCH, IMPLEMENT, LINT, TEST, DOCUMENT, PULL REQUEST)
  - `AIN [2025-12-16] NOTIFICATION_SETTINGS.md`
  - `AIN [2025-12-14] DESIGN_BOAT_IMPORT_FROM_CSV.md`

Each document follows the template structure with all phases in sections:

- **1: CONCEPT/CHANGE/CORRECTION** - Discuss ideas, changes, corrections without generating code
- **2: DESIGN** - Design detailed solution
- **3: PLAN** - Create implementation plan
- **4: REVIEW** - Review and validate the implementation plan
- **5: BRANCH** - Create Git branches for required repos
- **6: IMPLEMENT** - Execute the plan
- **7: LINT** - Check and fix linting issues
- **8: TEST** - Run tests
- **9: DOCUMENT** - Document the solution
- **10: PULL REQUEST** - Create PRs for all repos

## Related Files

- **Template**: `.github/docs/AI/AIN [20YY-MM-DD] WORKFLOW_TEMPLATE.md`
- **AI Rules**: `.github/docs/AI/AI-RULES.md`
- **Component Rules**: `.cursor/rules/*.mdc`
