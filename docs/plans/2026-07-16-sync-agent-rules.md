# Sync Agent Rules and Symbolic Links Implementation Plan

> **For Claude:** REQUIRED: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Synchronize the rule reorganization and relative symbolic links from `flutter_inspector` to `~/AiWorkspace/AI-Chat`.

**Architecture:** Create `.claude/rules` in the target project, copy rules files, remove the physical `.agents/rules` directory, and create relative symbolic links for rules and skills.

**Tech Stack:** Bash, Git, Symbolic Links

---

## Chunk 1: Directory Setup and File Copy

### Task 1: Create `.claude/rules` directory in AI-Chat
**Files:**
- Create: `/Users/yomiry/AiWorkspace/AI-Chat/.claude/rules`

- [ ] **Step 1: Run mkdir to create the target directory**
  Run: `mkdir -p /Users/yomiry/AiWorkspace/AI-Chat/.claude/rules`
  Expected: Command succeeds and directory is created.

### Task 2: Copy rules files from flutter_inspector to AI-Chat
**Files:**
- Copy from: `/Users/yomiry/StudioWorkspace/flutter_inspector/.claude/rules/`
- Copy to: `/Users/yomiry/AiWorkspace/AI-Chat/.claude/rules/`

- [ ] **Step 1: Copy rules files**
  Run: `cp /Users/yomiry/StudioWorkspace/flutter_inspector/.claude/rules/*.md /Users/yomiry/AiWorkspace/AI-Chat/.claude/rules/`
  Expected: 3 markdown files copied successfully.

- [ ] **Step 2: Verify copied files exist**
  Run: `ls -la /Users/yomiry/AiWorkspace/AI-Chat/.claude/rules/`
  Expected:
  - `expert-rules.md`
  - `flutter-styles.md`
  - `rtk-rules.md`
  all exist in target.

---

## Chunk 2: Symbolic Link Reconfiguration

### Task 3: Replace `.agents/rules` with relative symbolic link
**Files:**
- Modify: `/Users/yomiry/AiWorkspace/AI-Chat/.agents`

- [ ] **Step 1: Remove the existing physical `.agents/rules` directory**
  Run: `rm -rf /Users/yomiry/AiWorkspace/AI-Chat/.agents/rules`
  Expected: Directory and its content are removed.

- [ ] **Step 2: Create relative symbolic link for rules**
  Run: `ln -s ../.claude/rules /Users/yomiry/AiWorkspace/AI-Chat/.agents/rules`
  Expected: Symbolic link `rules -> ../.claude/rules` is created.

### Task 4: Recreate `.agents/skills` symbolic link as relative path
**Files:**
- Modify: `/Users/yomiry/AiWorkspace/AI-Chat/.agents`

- [ ] **Step 1: Remove absolute symbolic link of skills**
  Run: `rm -f /Users/yomiry/AiWorkspace/AI-Chat/.agents/skills`
  Expected: Old link is removed.

- [ ] **Step 2: Create relative symbolic link for skills**
  Run: `ln -s ../.claude/skills /Users/yomiry/AiWorkspace/AI-Chat/.agents/skills`
  Expected: Symbolic link `skills -> ../.claude/skills` is created.

- [ ] **Step 3: Verify all symbolic links in `.agents`**
  Run: `ls -la /Users/yomiry/AiWorkspace/AI-Chat/.agents`
  Expected:
  - `rules -> ../.claude/rules`
  - `skills -> ../.claude/skills`
  - `hooks -> ../.claude/hooks` (or whatever relative path hooks has)

---

## Chunk 3: Git Verification and Commit

### Task 5: Check git status and diff in AI-Chat
**Files:**
- Verify: `/Users/yomiry/AiWorkspace/AI-Chat`

- [ ] **Step 1: Check git status**
  Run: `git -C /Users/yomiry/AiWorkspace/AI-Chat status`
  Expected: Shows modifications/deletions on `.agents/rules`, `.agents/skills` and new untracked files in `.claude/rules/`.

- [ ] **Step 2: Review diff**
  Run: `git -C /Users/yomiry/AiWorkspace/AI-Chat diff`
  Expected: Git diff shows deleted files in old paths and new symbolic links.

### Task 6: Commit changes in AI-Chat
**Files:**
- Commit: `/Users/yomiry/AiWorkspace/AI-Chat`

- [ ] **Step 1: Add all changes to staging**
  Run: `git -C /Users/yomiry/AiWorkspace/AI-Chat add -A`
  Expected: Command succeeds.

- [ ] **Step 2: Commit with chore message**
  Run: `git -C /Users/yomiry/AiWorkspace/AI-Chat commit -m "chore(rules): sync agent rules and relative symbolic links from flutter_inspector"`
  Expected: Changes are committed successfully.
