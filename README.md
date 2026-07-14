# AI Agent YouTube Subtitle Knowledge Base Builder (Agent-to-Agent Guide)

This repository outlines the automated workflow for AI Agents to extract subtitles from a YouTube channel, parse and clean the transcripts, build a structured three-layer Obsidian Second Brain database, and utilize it for automated lesson/teaching planning.

> This guide is formatted specifically for consumption by agentic AI coders (such as Claude Code, Codex, AntiGravity, OpenCode). If you are an Agent reading this repo, follow the instructions and run the scripts below to replicate the knowledge base construction.

---

## System Architecture

```mermaid
graph TD
    Channel[@sensebar Channel] -->|1. extract_videos.py| VideoList[Filtered Video List & URLs]
    VideoList -->|2. download_all_subs.py| TempVTT[Raw VTT Subtitles]
    TempVTT -->|3. VTT Cleaning Engine| CleanMD[Deduplicated Markdown Files]
    CleanMD -->|4. Obsidian Vault| ThreeLayer[Three-Layer Vault Structure]
    ThreeLayer -->|5. Weekly Agent Task| KB[Structured Knowledge Base]
```

---

## Step-by-Step Implementation Workflow

### Step 1: Filter Channel Videos & Extract URLs
Use `extract_videos.py` to fetch video metadata, filter by keywords (`claude`, `codex`, `antigravity`, `opencode`, `agent`), and export URLs.

### Step 2: Download Subtitles & Clean VTT
Use `download_all_subs.py` to loop through URLs, download subtitles via `yt-dlp`, and clean:
1. Remove VTT metadata headers and timestamps
2. Strip HTML/XML tags
3. Deduplicate scrolling lines
4. Write clean Markdown files

### Step 3: Establish the Three-Layer Obsidian Vault
- `Clipping/` — raw transcript files (do not modify)
- `創作庫/` — your own scripts, lecture drafts, original notes
- `知識庫/` — structured knowledge managed by Agent

### Step 4: Run Weekly Agent Restructuring
1. Scan `Clipping/` and `創作庫/` for new files
2. Digest transcripts, extract summaries/topics
3. Write structured notes into `知識庫/`
4. Perform health check (lint)
5. Update Index and Log notes

### Step 5: Process Teaching Files & Write Plans
- Lesson/curriculum plan generation
- Auto-downloading & OCR
- Web interactive cockpit (教學駕駛艙)
