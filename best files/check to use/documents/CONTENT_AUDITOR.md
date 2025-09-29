# Content Policy Auditor

A powerful content auditing tool that enforces content guidelines across your built website pages.

## Features

### 🎯 **Smart Content Analysis**
- Scans built HTML pages (`dist/**/*.html`) + adjacent TypeScript files (`src/pages/**/*.ts`)
- Focuses on main content areas, excludes global components (nav, footer, sidebar)
- Uses phrase-boundary matching to avoid false positives

### 📝 **Policy Definition**
- JSON-based content policies with route patterns
- `must` rules: Required phrases that should be present
- `forbid` rules: Phrases that must not appear
- Lexicon system for reusable phrase buckets

### 🔍 **Enhanced Failure Reporting**
- **Context snippets**: Shows exactly where forbidden phrases appear
- **Occurrence counts**: How many times each phrase appears
- **Phrase analysis**: Summary of most common violations
- **Multiple output formats**: Human-readable text or machine-readable JSON

## Usage

### Basic Commands

```bash
# Standard audit with current policy
npm run audit:content

# Strict audit (more restrictive rules)
npm run audit:content:strict

# JSON output for CI/automation
npm run audit:content:json

# Verbose mode (shows all context snippets)
npm run audit:content:verbose
```

### Direct Commands

```bash
# Use custom policy file
node scripts/audit-content.mjs path/to/your-policy.json

# Combine flags
node scripts/audit-content.mjs content-policy.json --json --verbose
```

## Content Policy Format

```json
{
  "routes": [
    {
      "glob": "/services/bathroom-deep-clean/**",
      "must": ["bathroom", "tiles", "grout"],
      "forbid": ["bond clean", "end of lease"]
    }
  ],
  "lexicon": {
    "quality": ["7-day re-clean", "insured", "police-checked"]
  }
}
```

### Route Patterns
- `"/services/bond-cleaning/**"` - All bond cleaning pages
- `"/services/*/index.html"` - Main service pages only  
- `"/**"` - All pages

### Rule Types
- **Literal phrases**: `"bond clean"` (exact phrase match)
- **Lexicon references**: `"quality"` (any phrase from the quality bucket)

## Example Output

### Text Format (Human-Readable)
```
FAIL   /services/bathroom-deep-clean/ipswich/  →  dist/services/bathroom-deep-clean/ipswich/index.html
   forbidden:
     forbid:"bond clean" (1 occurrence)
       → ...customise your clean the standard bond clean included what's included...

📊 Most common forbidden phrases:
   "bond clean": 68 occurrences across 68 pages
```

### JSON Format (CI/Automation)
```json
{
  "summary": { "total": 190, "pass": 120, "fail": 70 },
  "problems": [
    {
      "route": "/services/bathroom-deep-clean/ipswich/",
      "forbidden": [
        {
          "phrase": "bond clean",
          "matches": [
            {
              "position": 245,
              "context": "...customise your clean the standard bond clean included..."
            }
          ]
        }
      ]
    }
  ]
}
```

## Integration

### CI/CD Pipeline
```yaml
- name: Content Audit
  run: npm run audit:content:json > content-audit.json
  
- name: Upload Report
  uses: actions/upload-artifact@v3
  with:
    name: content-audit-report
    path: content-audit.json
```

### Build Process
Add to your `package.json`:
```json
{
  "scripts": {
    "postbuild": "npm run audit:content"
  }
}
```

## Benefits

1. **Prevents Cross-Service Content Bleed**: Bathroom pages won't accidentally mention bond cleaning
2. **Ensures Required Content**: Every service page contains essential keywords
3. **Scales with Your Site**: Automatically checks all pages matching your patterns
4. **Developer Friendly**: Clear error messages with exact locations
5. **CI/CD Ready**: JSON output for automated pipelines

## Policy Examples

### Strict Service Separation
```json
{
  "routes": [
    {
      "glob": "/services/bond-cleaning/**",
      "must": ["bond clean", "end of lease"],
      "forbid": ["spring clean", "bathroom-only"]
    },
    {
      "glob": "/services/spring-cleaning/**", 
      "must": ["spring clean"],
      "forbid": ["bond clean", "end of lease"]
    }
  ]
}
```

### Quality Assurance
```json
{
  "routes": [
    {
      "glob": "/services/**",
      "must": ["quality-indicators", "local-proof"],
      "forbid": ["competitors"]
    }
  ],
  "lexicon": {
    "quality-indicators": ["insured", "7-day re-clean", "police-checked"],
    "local-proof": ["Ipswich", "Brisbane", "Logan"],
    "competitors": ["Jim's Cleaning", "Fantastic Services"]
  }
}
```
