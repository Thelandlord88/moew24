#!/bin/bash
# Bob's Code Analysis and Improvement Tool
# Systematic code quality assessment with battle-tested improvements

set -euo pipefail

analyze_code_file() {
    local file_path="$1"
    local file_ext="${file_path##*.}"
    
    echo "🔍 Bob's Analysis: $(basename "$file_path")"
    echo "========================================="
    
    case "$file_ext" in
        ts|js|mjs)
            analyze_typescript_javascript "$file_path"
            ;;
        py)
            analyze_python "$file_path"
            ;;
        sh)
            analyze_shell_script "$file_path"
            ;;
        astro)
            analyze_astro_component "$file_path"
            ;;
        *)
            echo "  📝 File type not yet supported by Bob's analyzer"
            ;;
    esac
}

analyze_typescript_javascript() {
    local file="$1"
    
    echo "📊 Code Metrics:"
    echo "  📏 Lines: $(wc -l < "$file")"
    echo "  🔧 Functions: $(grep -c "function\|=>" "$file" 2>/dev/null || echo "0")"
    echo "  📦 Imports: $(grep -c "^import\|require(" "$file" 2>/dev/null || echo "0")"
    
    echo ""
    echo "🎯 Bob's Production Readiness Assessment:"
    
    # Check for error handling
    local try_catch_count=$(grep -c "try\|catch" "$file" 2>/dev/null || echo "0")
    if [[ $try_catch_count -eq 0 ]]; then
        echo "  ⚠️ No error handling detected - production risk"
    else
        echo "  ✅ Error handling present ($try_catch_count instances)"
    fi
    
    # Check for input validation
    if grep -q "typeof\|Array\.isArray\|instanceof" "$file" 2>/dev/null; then
        echo "  ✅ Input validation detected"
    else
        echo "  ⚠️ Missing input validation - assumes clean data"
    fi
    
    # Check for magic numbers
    local magic_numbers
    magic_numbers=$(grep -o "[^a-zA-Z_][0-9]\{2,\}" "$file" 2>/dev/null | wc -l) || magic_numbers=0
    if [[ $magic_numbers -gt 5 ]]; then
        echo "  ⚠️ Potential magic numbers detected ($magic_numbers)"
    else
        echo "  ✅ Minimal magic numbers"
    fi
    
    # Check for documentation
    local comment_count code_lines doc_ratio
    comment_count=$(grep -c "//\|/\*\|\*" "$file" 2>/dev/null) || comment_count=0
    code_lines=$(grep -cv "^\s*$\|^\s*//" "$file" 2>/dev/null) || code_lines=1
    doc_ratio=$((comment_count * 100 / code_lines))
    
    if [[ $doc_ratio -lt 10 ]]; then
        echo "  ⚠️ Low documentation ratio ($doc_ratio%)"
    else
        echo "  ✅ Good documentation ratio ($doc_ratio%)"
    fi
    
    echo ""
    echo "💡 Bob's Recommendations:"
    suggest_improvements "$file"
}

analyze_shell_script() {
    local file="$1"
    
    echo "📊 Shell Script Metrics:"
    echo "  📏 Lines: $(wc -l < "$file")"
    echo "  🔧 Functions: $(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" "$file" 2>/dev/null || echo "0")"
    echo "  📦 Sources: $(grep -c "^\s*\." "$file" 2>/dev/null || echo "0")"
    
    echo ""
    echo "🎯 Bob's Shell Script Production Assessment:"
    
    # Check for error handling
    if grep -q "set -e\|set -o errexit" "$file" 2>/dev/null; then
        echo "  ✅ Exit on error enabled"
    else
        echo "  ⚠️ Missing 'set -e' - script continues on errors"
    fi
    
    # Check for undefined variable protection
    if grep -q "set -u\|set -o nounset" "$file" 2>/dev/null; then
        echo "  ✅ Undefined variable protection enabled"
    else
        echo "  ⚠️ Missing 'set -u' - undefined variables are silent"
    fi
    
    # Check for pipefail
    if grep -q "set -o pipefail\|set -euo pipefail" "$file" 2>/dev/null; then
        echo "  ✅ Pipeline failure detection enabled"
    else
        echo "  ⚠️ Missing 'set -o pipefail' - pipe failures go unnoticed"
    fi
    
    # Check for input validation
    if grep -q "if.*\$#\|test.*\$#" "$file" 2>/dev/null; then
        echo "  ✅ Argument validation detected"
    else
        echo "  ⚠️ Missing argument count validation"
    fi
    
    # Check for path handling
    if grep -q "dirname.*0\|cd.*dirname" "$file" 2>/dev/null; then
        echo "  ✅ Safe path handling detected"
    else
        echo "  ⚠️ Potential path dependency issues"
    fi
    
    echo ""
    echo "💡 Bob's Shell Script Recommendations:"
    suggest_shell_improvements "$file"
}

suggest_shell_improvements() {
    local file="$1"
    
    if ! grep -q "set -euo pipefail" "$file" 2>/dev/null; then
        echo "  🛡️ Add 'set -euo pipefail' for robust error handling"
    fi
    
    if ! grep -q "Usage:" "$file" 2>/dev/null; then
        echo "  📖 Add usage documentation for script arguments"
    fi
    
    if grep -q "\$[0-9]" "$file" 2>/dev/null && ! grep -q "if.*\$#" "$file" 2>/dev/null; then
        echo "  🔢 Validate argument count before using positional parameters"
    fi
    
    if ! grep -q "trap\|cleanup" "$file" 2>/dev/null; then
        echo "  🧹 Add cleanup trap for temporary files/processes"
    fi
    
    if grep -q "rm -rf" "$file" 2>/dev/null; then
        echo "  ⚠️ Review 'rm -rf' usage - ensure paths are validated"
    fi
    
    echo "  📝 Add comprehensive logging with timestamps"
    echo "  🎯 Include progress indicators for long-running operations"
    echo "  🔍 Add dry-run mode for testing"
}

analyze_astro_component() {
    local file="$1"
    
    echo "🚀 Astro Component Analysis:"
    echo "  📏 Total Lines: $(wc -l < "$file")"
    echo "  📄 Component: $(basename "$file" .astro)"
    
    # Extract frontmatter (TypeScript section)
    local frontmatter_lines=$(awk '/^---$/{flag=!flag; if(flag) next} flag' "$file" | wc -l || echo "0")
    echo "  🧠 Frontmatter: $frontmatter_lines lines of logic"
    
    # Extract template section
    local template_start=$(grep -n '^---$' "$file" | tail -1 | cut -d: -f1 || echo "1")
    local template_lines=$(($(wc -l < "$file") - template_start))
    echo "  🎨 Template: $template_lines lines of markup"
    
    echo ""
    echo "🎯 Bob's Astro Production Assessment:"
    
    # Check for error handling in frontmatter
    if grep -q "try\|catch\|throw" "$file" 2>/dev/null; then
        echo "  ✅ Error handling detected in component logic"
    else
        echo "  ⚠️ No error handling - component assumes perfect data"
    fi
    
    # Check for input validation/props validation
    if grep -q "interface.*Props\|type.*Props\|Astro.props" "$file" 2>/dev/null; then
        echo "  ✅ Props interface detected"
        if grep -q "z\.\|Zod\|validation\|validate" "$file" 2>/dev/null; then
            echo "  ✅ Runtime validation detected"
        else
            echo "  ⚠️ No runtime validation - trusts all props"
        fi
    else
        echo "  ⚠️ No props interface - untyped component"
    fi
    
    # Check for accessibility
    if grep -q "aria-\|role=\|alt=\|tabindex" "$file" 2>/dev/null; then
        echo "  ✅ Accessibility attributes detected"
    else
        echo "  ⚠️ Missing accessibility attributes"
    fi
    
    # Check for form validation (if it's a form component)
    if grep -q "form\|input\|button\|submit" "$file" 2>/dev/null; then
        echo "  📋 Form component detected"
        if grep -q "required\|pattern\|minlength\|maxlength" "$file" 2>/dev/null; then
            echo "  ✅ HTML5 validation attributes present"
        else
            echo "  ⚠️ Missing HTML5 validation"
        fi
        
        if grep -q "onsubmit\|addEventListener\|handleSubmit" "$file" 2>/dev/null; then
            echo "  ✅ JavaScript form handling detected"
        else
            echo "  ⚠️ No client-side form handling"
        fi
    fi
    
    # Check for performance considerations
    if grep -q "client:" "$file" 2>/dev/null; then
        echo "  🔄 Client-side hydration directives found"
        local client_directives=$(grep -c "client:" "$file" 2>/dev/null || echo "0")
        if [[ $client_directives -gt 3 ]]; then
            echo "  ⚠️ Many hydration directives ($client_directives) - performance risk"
        fi
    fi
    
    # Check for inline styles (maintainability issue)
    if grep -q "style=" "$file" 2>/dev/null; then
        local inline_styles=$(grep -c "style=" "$file" 2>/dev/null || echo "0")
        echo "  ⚠️ Inline styles detected ($inline_styles) - maintainability concern"
    fi
    
    echo ""
    echo "💡 Bob's Astro Component Recommendations:"
    suggest_astro_improvements "$file"
}

suggest_astro_improvements() {
    local file="$1"
    
    # Props and validation
    if ! grep -q "interface.*Props" "$file" 2>/dev/null; then
        echo "  🎯 Define strict Props interface with TypeScript"
    fi
    
    if ! grep -q "z\.\|Zod\|validate" "$file" 2>/dev/null; then
        echo "  🛡️ Add runtime props validation with Zod"
    fi
    
    # Error handling
    if ! grep -q "try.*catch" "$file" 2>/dev/null; then
        echo "  🚨 Wrap data fetching/processing in try-catch blocks"
    fi
    
    # Forms specific
    if grep -q "form\|input" "$file" 2>/dev/null; then
        echo "  📝 Add comprehensive form validation (client + server)"
        echo "  🔒 Implement CSRF protection for form submissions"
        echo "  ♿ Add ARIA labels and error announcements"
        echo "  🎯 Add loading states and submission feedback"
    fi
    
    # Performance 
    if grep -q "client:" "$file" 2>/dev/null; then
        echo "  ⚡ Review client directives - minimize JavaScript shipped"
        echo "  🔄 Use client:idle or client:visible for non-critical interactions"
    fi
    
    # Security
    echo "  🔐 Sanitize all user inputs and dynamic content"
    echo "  🛡️ Validate all external data sources"
    
    # Maintainability
    if grep -q "style=" "$file" 2>/dev/null; then
        echo "  🎨 Move inline styles to CSS classes or Astro styles"
    fi
    
    echo "  📚 Add JSDoc comments for complex component logic"
    echo "  🧪 Create component test coverage for edge cases"
    echo "  🔍 Add error boundaries for graceful failure handling"
}

suggest_improvements() {
    local file="$1"
    
    # Specific improvement suggestions based on patterns
    if grep -q "recursive\|function.*function" "$file" 2>/dev/null; then
        echo "  🔄 Consider iterative alternatives for recursive functions"
    fi
    
    if ! grep -q "validate\|check\|verify" "$file" 2>/dev/null; then
        echo "  🛡️ Add input validation functions"
    fi
    
    if grep -q "console\.log" "$file" 2>/dev/null; then
        echo "  📝 Replace console.log with proper logging"
    fi
    
    if ! grep -q "test\|spec\|\.test\." "$file" 2>/dev/null; then
        echo "  🧪 Add comprehensive test coverage"
    fi
    
    echo "  📚 Document WHY decisions were made, not just WHAT"
    echo "  🎯 Add performance metrics for critical paths"
    echo "  🔍 Include edge case handling for production data"
}

# Main function for file analysis
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <file_to_analyze>"
        exit 1
    fi
    
    analyze_code_file "$1"
fi
