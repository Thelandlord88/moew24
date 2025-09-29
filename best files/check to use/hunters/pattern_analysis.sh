#!/bin/bash
# Pattern Analysis Hunter - Detects coding patterns and suggests improvements
# Part of Hunter Thinker 2.0 system

echo "🔍 PATTERN ANALYSIS HUNTER"
echo "=========================="
echo ""

REPORT_FILE="__reports/hunt/pattern_analysis.json"
mkdir -p "__reports/hunt"

# Target files/directories to analyze (can be customized)
TARGET_DIRS=${1:-"src/components src/pages src/utils src/lib"}
PATTERN_FOCUS=${2:-"component|util|page"}

echo "📂 ANALYZING PATTERNS IN: $TARGET_DIRS"
echo "🎯 FOCUS: $PATTERN_FOCUS"
echo ""

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
{
  "timestamp": "",
  "module": "pattern_analysis",
  "status": "info",
  "target_directories": [],
  "patterns_detected": {},
  "anti_patterns": {},
  "architectural_opportunities": {},
  "consistency_metrics": {},
  "recommendations": [],
  "code_smells": {},
  "design_patterns": {},
  "improvement_suggestions": []
}
EOF

echo "🔍 PATTERN DETECTION ANALYSIS"
echo "============================="

# Function to analyze import patterns
analyze_import_patterns() {
  echo "🔗 Import Pattern Analysis:"
  
  # Find relative vs absolute imports
  relative_imports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.astro" -o -name "*.js" 2>/dev/null | xargs grep -h "^import.*from ['\"]\./" 2>/dev/null | wc -l)
  absolute_imports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.astro" -o -name "*.js" 2>/dev/null | xargs grep -h "^import.*from ['\"]~/" 2>/dev/null | wc -l)
  
  echo "  Relative imports (./../): $relative_imports"
  echo "  Absolute imports (~/): $absolute_imports"
  
  # Detect barrel imports
  barrel_imports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.astro" -o -name "*.js" 2>/dev/null | xargs grep -h "import.*from.*index" 2>/dev/null | wc -l)
  echo "  Barrel imports: $barrel_imports"
  
  # Most common import sources
  echo "  Top import sources:"
  find $TARGET_DIRS -name "*.ts" -o -name "*.astro" -o -name "*.js" 2>/dev/null | xargs grep -h "^import.*from" 2>/dev/null | sed "s/.*from ['\"]//; s/['\"].*//" | sort | uniq -c | sort -nr | head -5 | sed 's/^/    /'
}

# Function to analyze component patterns
analyze_component_patterns() {
  echo ""
  echo "🧩 Component Pattern Analysis:"
  
  # Find Astro components
  astro_components=$(find $TARGET_DIRS -name "*.astro" 2>/dev/null | wc -l)
  echo "  Astro components: $astro_components"
  
  # Find TypeScript files
  ts_files=$(find $TARGET_DIRS -name "*.ts" 2>/dev/null | wc -l)
  echo "  TypeScript files: $ts_files"
  
  # Find JavaScript files
  js_files=$(find $TARGET_DIRS -name "*.js" 2>/dev/null | wc -l)
  echo "  JavaScript files: $js_files"
  
  # Component size analysis
  echo "  Component size analysis:"
  find $TARGET_DIRS -name "*.astro" 2>/dev/null | while read file; do
    lines=$(wc -l < "$file")
    echo "    $(basename "$file"): $lines lines"
  done | sort -k2 -nr | head -5
  
  # Props pattern analysis
  echo "  Props patterns detected:"
  prop_interfaces=$(find $TARGET_DIRS -name "*.astro" 2>/dev/null | xargs grep -l "interface.*Props" 2>/dev/null | wc -l)
  inline_props=$(find $TARGET_DIRS -name "*.astro" 2>/dev/null | xargs grep -l "const.*Astro.props" 2>/dev/null | wc -l)
  echo "    Interface Props: $prop_interfaces"
  echo "    Inline Props: $inline_props"
}

# Function to analyze utility patterns
analyze_utility_patterns() {
  echo ""
  echo "🛠️ Utility Pattern Analysis:"
  
  # Find utility functions
  util_exports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -h "^export.*function\|^export const.*=" 2>/dev/null | wc -l)
  echo "  Exported functions: $util_exports"
  
  # Default exports vs named exports
  default_exports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "export default" 2>/dev/null | wc -l)
  named_exports=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "export {" 2>/dev/null | wc -l)
  echo "  Default exports: $default_exports"
  echo "  Named exports: $named_exports"
  
  # Function complexity (rough estimate by lines)
  echo "  Function complexity (largest functions):"
  find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -n "function\|const.*=.*=>" 2>/dev/null | head -5 | sed 's/^/    /'
}

# Function to detect anti-patterns
detect_anti_patterns() {
  echo ""
  echo "⚠️ ANTI-PATTERN DETECTION:"
  
  # Magic numbers
  magic_numbers=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" -o -name "*.astro" 2>/dev/null | xargs grep -E "\b[0-9]{3,}\b" 2>/dev/null | wc -l)
  echo "  Magic numbers detected: $magic_numbers"
  
  # Console.log statements
  console_logs=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" -o -name "*.astro" 2>/dev/null | xargs grep -c "console\.log" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
  echo "  Console.log statements: $console_logs"
  
  # Hardcoded strings
  hardcoded_strings=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" -o -name "*.astro" 2>/dev/null | xargs grep -E "\"[^\"]{20,}\"" 2>/dev/null | wc -l)
  echo "  Long hardcoded strings (>20 chars): $hardcoded_strings"
  
  # TODO/FIXME comments
  todo_comments=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" -o -name "*.astro" 2>/dev/null | xargs grep -i "TODO\|FIXME\|HACK" 2>/dev/null | wc -l)
  echo "  TODO/FIXME comments: $todo_comments"
  
  # Duplicate code (simple pattern matching)
  echo "  Potential duplicate patterns:"
  find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -h "const.*=.*{" 2>/dev/null | sort | uniq -d | head -3 | sed 's/^/    /'
}

# Function to suggest architectural improvements
suggest_improvements() {
  echo ""
  echo "💡 ARCHITECTURAL IMPROVEMENT OPPORTUNITIES:"
  
  # File organization patterns
  echo "  File Organization Analysis:"
  component_depth=$(find $TARGET_DIRS -name "*.astro" -type f | sed 's|[^/]||g' | wc -c | awk '{print $1/NR}' RS= 2>/dev/null)
  echo "    Average component nesting depth: ${component_depth:-0}"
  
  # Naming conventions
  echo "  Naming Convention Analysis:"
  camel_case=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -h "const [a-z][a-zA-Z]*" 2>/dev/null | wc -l)
  kebab_case=$(find $TARGET_DIRS -name "*-*" 2>/dev/null | wc -l)
  pascal_case=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -h "const [A-Z][a-zA-Z]*" 2>/dev/null | wc -l)
  
  echo "    camelCase variables: $camel_case"
  echo "    kebab-case files: $kebab_case"
  echo "    PascalCase variables: $pascal_case"
  
  # Type safety patterns
  echo "  Type Safety Analysis:"
  any_types=$(find $TARGET_DIRS -name "*.ts" 2>/dev/null | xargs grep -c ": any\|as any" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
  interface_usage=$(find $TARGET_DIRS -name "*.ts" 2>/dev/null | xargs grep -c "interface " 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
  type_usage=$(find $TARGET_DIRS -name "*.ts" 2>/dev/null | xargs grep -c "type " 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
  
  echo "    'any' type usage: $any_types"
  echo "    Interface definitions: $interface_usage"
  echo "    Type aliases: $type_usage"
}

# Function to analyze design patterns
analyze_design_patterns() {
  echo ""
  echo "🎨 DESIGN PATTERN DETECTION:"
  
  # Singleton pattern
  singleton_patterns=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "export.*new\|getInstance" 2>/dev/null | wc -l)
  echo "  Singleton-like patterns: $singleton_patterns"
  
  # Factory pattern
  factory_patterns=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "create.*\|make.*\|build.*" 2>/dev/null | wc -l)
  echo "  Factory-like patterns: $factory_patterns"
  
  # Observer pattern
  observer_patterns=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "addEventListener\|subscribe\|emit" 2>/dev/null | wc -l)
  echo "  Observer-like patterns: $observer_patterns"
  
  # Module pattern
  module_patterns=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "export.*{" 2>/dev/null | wc -l)
  echo "  Module patterns: $module_patterns"
}

# Run all analyses
analyze_import_patterns
analyze_component_patterns
analyze_utility_patterns
detect_anti_patterns
suggest_improvements
analyze_design_patterns

echo ""
echo "📊 PATTERN ANALYSIS SUMMARY"
echo "==========================="

# Calculate metrics
total_files=$(find $TARGET_DIRS -name "*.ts" -o -name "*.js" -o -name "*.astro" 2>/dev/null | wc -l)
astro_files=$(find $TARGET_DIRS -name "*.astro" 2>/dev/null | wc -l)
ts_files=$(find $TARGET_DIRS -name "*.ts" 2>/dev/null | wc -l)
js_files=$(find $TARGET_DIRS -name "*.js" 2>/dev/null | wc -l)

echo "Total files analyzed: $total_files"
echo "Astro files: $astro_files"
echo "TypeScript files: $ts_files" 
echo "JavaScript files: $js_files"

# Determine status based on findings
if [ $console_logs -gt 10 ] || [ $any_types -gt 5 ] || [ $magic_numbers -gt 20 ]; then
  status="warn"
  issues=$((console_logs + any_types + magic_numbers))
elif [ $todo_comments -gt 15 ] || [ $hardcoded_strings -gt 10 ]; then
  status="warn"
  issues=$((todo_comments + hardcoded_strings))
else
  status="info"
  issues=0
fi

echo "Status: $status"
echo "Issues identified: $issues"

# Generate recommendations based on patterns
echo ""
echo "💡 RECOMMENDATIONS:"
echo "=================="

if [ $relative_imports -gt $absolute_imports ]; then
  echo "• Consider standardizing on absolute imports (~/) for better maintainability"
fi

if [ $any_types -gt 3 ]; then
  echo "• Reduce 'any' type usage for better type safety"
fi

if [ $console_logs -gt 5 ]; then
  echo "• Remove console.log statements for production"
fi

if [ $magic_numbers -gt 10 ]; then
  echo "• Extract magic numbers into named constants"
fi

if [ $component_depth -gt 3 ]; then
  echo "• Consider flattening component directory structure"
fi

# Update report with findings
timestamp=$(date -u +"%Y%m%d-%H%M%S")

cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$timestamp",
  "module": "pattern_analysis",
  "status": "$status",
  "target_directories": ["$TARGET_DIRS"],
  "patterns_detected": {
    "import_patterns": {
      "relative_imports": $relative_imports,
      "absolute_imports": $absolute_imports,
      "barrel_imports": $barrel_imports
    },
    "component_patterns": {
      "astro_components": $astro_files,
      "typescript_files": $ts_files,
      "javascript_files": $js_files,
      "prop_interfaces": $prop_interfaces,
      "inline_props": $inline_props
    },
    "utility_patterns": {
      "exported_functions": $util_exports,
      "default_exports": $default_exports,
      "named_exports": $named_exports
    }
  },
  "anti_patterns": {
    "magic_numbers": $magic_numbers,
    "console_logs": $console_logs,
    "hardcoded_strings": $hardcoded_strings,
    "todo_comments": $todo_comments
  },
  "architectural_opportunities": {
    "type_safety": {
      "any_types": $any_types,
      "interface_usage": $interface_usage,
      "type_usage": $type_usage
    },
    "naming_conventions": {
      "camel_case": $camel_case,
      "kebab_case": $kebab_case,
      "pascal_case": $pascal_case
    }
  },
  "design_patterns": {
    "singleton_like": $singleton_patterns,
    "factory_like": $factory_patterns,
    "observer_like": $observer_patterns,
    "module_patterns": $module_patterns
  },
  "consistency_metrics": {
    "total_files": $total_files,
    "component_depth": $component_depth,
    "type_safety_score": $((100 - any_types * 5))
  },
  "issues": $issues,
  "critical": 0,
  "recommendations": [
    "Standardize import patterns",
    "Improve type safety",
    "Remove debugging code",
    "Extract magic numbers",
    "Consolidate similar patterns"
  ]
}
EOF

echo ""
echo "🎯 PATTERN ANALYSIS COMPLETE"
echo "============================"
echo "Status: $status"
echo "Issues found: $issues"
echo "Report saved: $REPORT_FILE"

# Exit with appropriate code
if [ "$status" = "critical" ]; then
  exit 2
elif [ "$status" = "warn" ]; then
  exit 1
else
  exit 0
fi
