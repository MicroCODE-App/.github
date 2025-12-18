# AI Rules - Workflow Document Editing

## Workflow Documents

When working on **workflow documents** (AIN files or Issue Template derivatives):

### Continuous Editing Rule

**IMPORTANT**: When editing workflow documents, you should:

1. **Edit continuously** - Make all requested edits to the workflow document without stopping to ask for approval
2. **No approval prompts** - Do not pause to ask "should I continue?" or "do you want to accept these changes?"
3. **Complete the section** - Finish editing the entire section (CONCEPT, DESIGN, PLAN, REVIEW, etc.) before moving on
4. **Apply user feedback immediately** - When the user provides feedback or corrections, apply them immediately and continue

### What This Applies To

✅ **Applies to**:

- **AIN Documents**: Editing sections in Architecture Implementation Notes (`.github/docs/AINs/*.md`)
- **Issue Templates**: Editing Issue Template derivatives (`.issue/.github/ISSUE_TEMPLATE/**/*.md`)
  - Bugfix templates: `bugfix/bugfix-nnnn--bugfix-short-name.md`
  - Feature templates: `feature/feature-nnnn--feature-short-name.md`
  - Hotfix templates: `hotfix/hotfix-nnnn--hotfix-short-name.md`
  - Release templates: `release/release-bM.F.0.md`
  - Security templates: `security/security-nnnn--vulnerability-short-name.md`
- Updating CONCEPT, DESIGN, PLAN, REVIEW sections
- Refining documentation based on user feedback
- Adding details, clarifications, or corrections to workflow documents

❌ **Does NOT apply to**:

- Actual code implementation (still requires explicit approval)
- Creating new files outside of workflow documents
- Making changes to codebase files
- Running commands or tests

### Example Workflow

**Correct behavior**:

```
User: "Update the PLAN section to remove migration steps"
AI: [Immediately updates PLAN section, continues editing]
User: "Also rename 'messages' to 'notifications'"
AI: [Immediately updates all references, continues]
```

**Incorrect behavior**:

```
User: "Update the PLAN section"
AI: [Makes one edit, stops] "Should I continue with these changes?"
User: "Yes, keep going"
AI: [Makes another edit, stops again]
```

### When to Stop

Only stop editing workflow documents when:

- The user explicitly asks you to stop
- You encounter an error that prevents editing
- You need information that's not available in the document or codebase
- The user asks a question that requires clarification before proceeding

### Implementation vs Documentation

- **Workflow Documents** (AIN files and Issue Template derivatives): Edit continuously, no approval needed
- **Code Files**: Still require explicit approval before implementation (per existing rules)
