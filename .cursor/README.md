# Cursor Configuration Directory

This directory contains Cursor IDE configuration files to optimize AI-assisted development for the MicroCODE App Template monorepo.

## Structure

```
.github/.cursor/
├── .cursorrules         # Root-level rules (references AI-RULES.md)
├── instructions.md      # Project context and architecture overview
├── rules/               # Component-specific rules
│   ├── server.mdc       # Server/backend rules
│   ├── client.mdc       # React web client rules
│   ├── app.mdc          # React Native mobile app rules
│   ├── admin.mdc        # Admin console rules
│   └── portal.mdc       # Astro marketing site rules
├── commands/            # Cursor custom commands (workflow phases)
│   ├── 0-workflow.md    # Workflow overview
│   ├── 1-concept.md     # CONCEPT phase
│   ├── 2-design.md      # DESIGN phase
│   ├── 3-plan.md        # PLAN phase
│   ├── 4-review.md      # REVIEW phase
│   ├── 5-branch.md      # BRANCH phase
│   ├── 6-implement.md   # IMPLEMENT phase
│   ├── 7-lint.md        # LINT phase
│   ├── 8-test.md        # TEST phase
│   ├── 9-document.md    # DOCUMENT phase
│   └── 10-pull-request.md # PULL REQUEST phase
├── context/             # Context and reference files
│   └── workflow-reference.md
└── README.md            # This file
```

## How It Works

### `.cursorrules`

The root-level rules file that Cursor reads first. It:

- References the comprehensive AI-RULES.md documentation
- Provides monorepo context
- Links to component-specific rules
- Establishes core principles

### `instructions.md`

Detailed project instructions that provide:

- Architecture overview of all five components
- Technology stack details
- Common patterns and examples
- Development workflow information

### `rules/*.mdc`

Component-specific rules using Cursor's `.mdc` format:

- **Frontmatter**: Defines which files the rules apply to (`globs`)
- **Content**: Detailed rules for that specific component
- **Auto-application**: Rules marked `alwaysApply: true` are always active

## Usage

When working in Cursor:

1. **Cursor automatically reads** `.github/.cursor/.cursorrules` for root-level guidance
2. **Component-specific rules** activate based on the files you're editing
3. **Use workflow commands** - Type `/` in Cursor chat to see available commands (`/0-workflow`, `/1-concept`, etc.)
4. **Reference `instructions.md`** for architectural context
5. **Check `AI-RULES.md`** for complete coding standards

## Component Rules

Each component has its own rule file:

- **`server.mdc`**: Node.js/Express backend patterns, database access, API structure
- **`client.mdc`**: React web frontend patterns, Shadcn UI, routing, forms
- **`app.mdc`**: React Native mobile app patterns, native features
- **`admin.mdc`**: Admin console patterns, security considerations
- **`portal.mdc`**: Astro static site patterns, SEO, content structure

## Best Practices

1. **Always reference** `.github/docs/AI/AI-RULES.md` for complete standards
2. **Check component rules** when working in specific directories
3. **Follow the workflow template** when starting new tasks
4. **Run ESLint** after edits using component-specific configs

## Commands

Custom Cursor commands are available in `.cursor/commands/`:

- **`/0-workflow`** - Complete workflow overview
- **`/1-concept`** through **`/10-pull-request`** - Workflow phase commands

Type `/` in Cursor chat to see and use these commands.

## Related Documentation

- **Complete AI Rules**: `.github/docs/AI/AI-RULES.md`
- **Developer Setup**: `.github/docs/DEV/DEVELOPER-SETUP.md`
- **Git Workflow**: `.github/docs/DEV/DEVELOPER-GIT.md`
- **Workflow Reference**: `.cursor/context/workflow-reference.md`
- **Component Rules**: `client/.cursorrules` (legacy, being migrated to `.github/.cursor/rules/`)

## Maintenance

- Update rules as patterns evolve
- Keep `instructions.md` synchronized with architecture changes
- Add new component rules as needed
- Reference this structure in onboarding documentation
