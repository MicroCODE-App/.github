#Requires AutoHotkey v2.0

/*
 * AI Development Workflow Hotkeys for Cursor IDE
 *
 * This script provides keyboard shortcuts for a structured AI-assisted development workflow.
 * Workflow sequence: Talk → Branch → Design → Plan → Implement → Lint → Test → Document → Pull Request
 *
 * Usage: Press ALT+SHIFT+[Key] to send the corresponding workflow instruction to Cursor's AI chat.
 */

; Helper function to send text reliably using clipboard (more reliable for long messages)
SendAIMessage(text, actionName) {
    ; Save current clipboard
    A_Clipboard := "`n"
    oldClipboard := ClipboardAll()

    ; Set new text to clipboard
    A_Clipboard := text

    ; Wait for clipboard to be ready
    ClipWait(0.5)

    ; Send using Ctrl+V (paste) - more reliable than SendText for long messages
    Send("^v")

    ; Restore original clipboard after a brief delay
    Sleep(100)
    A_Clipboard := oldClipboard

    ; Show brief tooltip feedback near mouse cursor
    MouseGetPos(&mouseX, &mouseY)
    ToolTip("Sent: " . actionName, mouseX + 10, mouseY + 10)
    SetTimer(() => ToolTip(), -2000) ; Remove tooltip after 2 seconds
}

; ============================================================================
; WORKFLOW HOTKEYS
; ============================================================================

; ALT-SHIFT-C: Concept/Change/Correction - Discuss ideas without generating code
!+c::
{
    message := "`nI have a CONCEPT I want to talk to you about, do not generate any changes, files, or code; just talk to me until I'm ready to start the development process with you. Make no assumptions about when that time comes. If you cannot access a file or resource I reference, STOP and ask me how to access it. Do not explore or read other files unless I explicitly ask you to. Ask me two questions to start: 1. Is there an existing GitHub Issue # assigned? 2. Is this a FEATURE, BUGFIX, HOTFIX or RELEASE? After asking, if there is an Issue #, start a new file from the existing templates in the centralized `.issue` repository. This document will be our place to write the design, document tests, capture results, etc. It will live with this change until the Pull-Request stores it permanently. If there is already an ISSUE Markdown started, open it and read what we have so far to get started.`n`n"
    SendAIMessage(message, "Concept")
}

; ALT-SHIFT-D: Design - Design detailed solution
!+d::
{
    message := "`nDESIGN a detailed solution to implement this change following the rules documented in .github/docs/AI/AI-RULES.md file. Include test cases for basic features by extending the existing /test structure in each repository. Make no changes at this time, simply create a detailed high-level DESIGN for the change, the details of the implementation will come after you have no questions about how to update the existing code in all repos for this change. And we reach a 95% or higher confidence level in the design. During this phase you have full access to read all files in the repos, but do NOT change anything except our references ISSUE_TEMPLATE working file.`n`n"
    SendAIMessage(message, "Design")
}

; ALT-SHIFT-P: Plan - Create implementation plan
!+p::
{
    message := "`nPLAN a detailed implementation of this design, do NOT change any code or files at this point. This phase should outline affected files, modules, and expected refactor areas. This plan should include diagrams, interface contracts, user stories, and any other documents required to implement a solid, secure, and complete implementation. Make no assumptions here, if something is unclear give me a list of questions to clarify before proceeding. Do not proceed with any code or file changes until I give you an explicit command to implement.`n`n"
    SendAIMessage(message, "Plan")
}

; ALT-SHIFT-V: Review - Validate the implementation plan
!+v::
{
    message := "`nREVIEW and validate our plan so far, give me a confidence rating from 0% to 100% on your ability to implement this plan in code. If there are any assumptions or questions remaining give me a list of questions to move us to at least 95% confidence. Do not proceed to CODE IMPLEMENTATION until I explicitly accept the plan or answer/waive the remaining questions. NOTE: Continue editing the workflow document itself (AIN files or Issue Template derivatives) without stopping - this approval requirement only applies to actual code implementation.`n`n"
    SendAIMessage(message, "Review")
}

; ALT-SHIFT-B: Branch - Create Git branches for all required repos
!+b::
{
    message := "`nBRANCH the required Repos. We are going to work on a change that may affect multiple Repos found in this directory. Start this work by creating a Git Branch for each Repo that will be affected by this change in this Github Collection. Name it by following our Git Workflow implementation rules, in DEVELOPER-GIT.md - `5. Branch Naming Conventions (GitHub Organizations with Multiple Repos)`. If you are not positive about the names for the branches, stop and ask me. List the repos you intend to branch in one place, with your intended names, before actually creating branches so I can confirm the scope.`n`n"
    SendAIMessage(message, "Branch")
}

; ALT-SHIFT-I: Implement - Execute the plan
!+i::
{
    message := "`nIMPLEMENT, this plan looks solid, go ahead and proceed with the implementation. Be elegant and follow our philosophy of 'Code like a Machine'. 'Consistently and Explicitly, Simply and for Readability. Hail CAESAR!' Follow the MicroCODE Style Guide for this: [MicroCODE JavaScript Style Guide.pdf] and the rules in .github/docs/AI/AI-RULES.md. Do not make any assumptions while coding. If you are not 100% confident on any implementation points after opening the code, STOP, and lets figure it out together interactively.`n`n"
    SendAIMessage(message, "Implement")
}

; ALT-SHIFT-L: Lint - Check and fix linting issues
!+l::
{
    message := "`nLINT everything using server/bin/lint.all.js, check for any warnings or errors, and fix them all WITHOUT modifying any eslint.config.js rules. If linting fails due to config limitations, raise a warning in the log but do not modify the rules.`n`n"
    SendAIMessage(message, "Lint")
}

; ALT-SHIFT-T: Test - Run tests (using S since T is used for Talk)
!+t::
{
    message := "`nTEST the solution using the code as designed and implemented. Generate logs and MD files with the results. Unit, integration, and smoke tests as applicable. Log output should be in both human-readable and machine-readable (e.g., JSON/MD) formats. Use the MOCHA tests defined by package.json and held in */test under each repo. Pass Criteria: All Tests must pass to call this phase complete, and tests should not be edited in order to pass without a discussion. If no tests exist for a repo, report that explicitly and propose at least one test to add (but do not create it without my approval). Do not proceed with any code or file storage in GitHub until I give you an explicit command to create a Pull Request.`n`n"
    SendAIMessage(message, "Test")
}

; ALT-SHIFT-M: Document - Document the solution
!+m::
{
    message := "`nDOCUMENT the implemented and successfully tested solution. Include updates to all affected README.md files. Ensure new or updated APIs are covered in relevant OpenAPI/Swagger schemas where applicable.`n`n"
    SendAIMessage(message, "Document")
}

; ALT-SHIFT-R: Pull Request - Create PRs for all repos
!+r::
{
    message := "`nCreate a PULL REQUEST for each affected Repo in this Github Organization to completely save this change; be sure to update the overall change log found in .github/CHANGELOG.md, including a tag lock to this PR. Ensure a git tag matching the PR number or release name is added post-merge.`n`n"
    SendAIMessage(message, "Pull Request")
}
