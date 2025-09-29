# 📊 Custom CSS Classes Usage Summary

**Generated:** 2025-08-30T22:40:33.867Z
**Focus:** Known custom classes from output.css

## 🎯 **Summary**

- **Custom classes analyzed:** 29
- **Classes used in application:** 17
- **Unused custom classes:** 12

---

## ✅ **USED CUSTOM CSS CLASSES**

*These classes MUST be migrated to src/styles/main.css*

### `.step-indicator` 🎯 Multi-step Form

**Usage:** 1 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
.step-indicator {
  position: relative;
  margin-bottom: 2rem;
  display: flex;
  justify-content: space-between;
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 8: `const stepIndicators = Array.from(document.querySelectorAll('.step-indicator .step'));`

---

### `.step` 🎯 Multi-step Form

**Usage:** 28 occurrence(s) across 3 file(s)

**CSS Definition:**
```css
.step {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  --tw-bg-opacity: 1;
  background-color: rgb(255 255 255 / var(--tw-bg-opacity, 1));
  padding-left: 0.5rem;
  padding-right: 0.5rem;
  z-index: 1;
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 7: `const formSteps = Array.from(form.querySelectorAll('.form-step'));`
  - Line 8: `const stepIndicators = Array.from(document.querySelectorAll('.step-indicator .step'));`

**📁 `src/components/QuoteForm.astro`**
  - Line 41: `<li data-step-label="1" class="q-stepper-item" aria-current="step"><span class="q-step-num">1</span><span>Property</span...`
  - Line 42: `<li data-step-label="2" class="q-stepper-item"><span class="q-step-num">2</span><span>Add-ons</span></li>`
  - Line 43: `<li data-step-label="3" class="q-stepper-item"><span class="q-step-num">3</span><span>Your info</span></li>`
  - ... and 22 more occurrences

**📁 `src/pages/blog/[cluster]/[slug].astro`**
  - Line 95: `<article class="max-w-3xl mx-auto py-12 px-4">`

---

### `.step-label` 🎯 Multi-step Form

**Usage:** 5 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
.step-label {
  text-align: center;
  font-size: 0.75rem;
  line-height: 1rem;
  font-weight: 500;
  --tw-text-opacity: 1;
  color: rgb(75 85 99 / var(--tw-text-opacity, 1));
}
```

**Files Using This Class:**
**📁 `src/components/QuoteForm.astro`**
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`
  - Line 41: `<li data-step-label="1" class="q-stepper-item" aria-current="step"><span class="q-step-num">1</span><span>Property</span...`
  - Line 42: `<li data-step-label="2" class="q-stepper-item"><span class="q-step-num">2</span><span>Add-ons</span></li>`
  - ... and 2 more occurrences

---

### `.form-step` 🎯 Multi-step Form

**Usage:** 1 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
.form-step {
  display: none;
  animation: fadeIn 0.5s ease;
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 7: `const formSteps = Array.from(form.querySelectorAll('.form-step'));`

---

### `.form-checkbox-label` 🎯 Multi-step Form

**Usage:** 1 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
display: block;
}

.form-checkbox-label.selected {
  --tw-border-opacity: 1;
  border-color: rgb(14 165 233 / var(--tw-border-opacity, 1));
  --tw-bg-opacity: 1;
  background-color: rgb(224 242 254 / var(--tw-bg-opacity, 1));
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 94: `form.querySelectorAll('.form-checkbox-label').forEach(label => {`

---

### `.active` 🔧 Utility

**Usage:** 11 occurrence(s) across 3 file(s)

**CSS Definition:**
```css
margin-bottom: 0.5rem;
  display: flex;
  height: 2.5rem;
  width: 2.5rem;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  border-width: 2px;
  --tw-border-opacity: 1;
  border-color: rgb(224 242 254 / var(--tw-border-opacity, 1));
  --tw-bg-opacity: 1;
  background-color: rgb(156 163 175 / var(--tw-bg-opacity, 1));
  font-weight: 600;
  --tw-text-opacity: 1;
  color: rgb(255 255 255 / var(--tw-text-opacity, 1));
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 300ms;
}

.step.active .step-number {
  --tw-bg-opacity: 1;
  background-color: rgb(14 165 233 / var(--tw-bg-opacity, 1));
  --tw-shadow: 0 0 0 4px rgba(14,165,233,0.2);
  --tw-shadow-colored: 0 0 0 4px var(--tw-shadow-color);
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 23: `if (index + 1 === currentStep) indicator.classList.add('active');`

**📁 `src/components/QuoteForm.astro`**
  - Line 66: `<div id="q-step-1" class="q-step active">`
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`
  - Line 67: `<div class="q-card">`
  - ... and 1 more occurrences

**📁 `src/components/Polaroid.astro`**
  - Line 26: `<figure class="group polaroid-card relative bg-white rounded-[1.5rem] shadow-xl border-2 border-gray-200 overflow-visibl...`
  - Line 43: `<figure class="group polaroid-card relative bg-white rounded-[1.5rem] shadow-xl border-2 border-gray-200 overflow-visibl...`
  - Line 60: `<figure class="group polaroid-card relative bg-white rounded-[1.5rem] shadow-xl border-2 border-gray-200 overflow-visibl...`
  - ... and 3 more occurrences

---

### `.completed` 🔧 Utility

**Usage:** 1 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
--tw-bg-opacity: 1;
  background-color: rgb(14 165 233 / var(--tw-bg-opacity, 1));
  --tw-shadow: 0 0 0 4px rgba(14,165,233,0.2);
  --tw-shadow-colored: 0 0 0 4px var(--tw-shadow-color);
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
}

.step.completed .step-number {
  --tw-bg-opacity: 1;
  background-color: rgb(12 47 90 / var(--tw-bg-opacity, 1));
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 22: `if (index + 1 < currentStep) indicator.classList.add('completed');`

---

### `.invalid` 🔧 Utility

**Usage:** 4 occurrence(s) across 2 file(s)

**CSS Definition:**
```css
--tw-border-opacity: 1;
  border-color: rgb(14 165 233 / var(--tw-border-opacity, 1));
  --tw-bg-opacity: 1;
  background-color: rgb(224 242 254 / var(--tw-bg-opacity, 1));
}

input.invalid, select.invalid, textarea.invalid {
  --tw-border-opacity: 1;
  border-color: rgb(239 68 68 / var(--tw-border-opacity, 1));
}
```

**Files Using This Class:**
**📁 `js/script.js`**
  - Line 39: `input.classList.add('invalid');`
  - Line 42: `input.classList.remove('invalid');`

**📁 `src/components/QuoteForm.astro`**
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`
  - Line 637: `this.prev=this.btn('<i class="fas fa-chevron-left"></i>', ()=>{this.view=addM(this.view,-1); this.render();});`

---

### `.thumbnail-item` 🖼️ Gallery

**Usage:** 3 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
.thumbnail-item {
  transition-property: transform;
  transition-duration: 300ms;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  animation: lift 8s ease-in-out infinite;
}
```

**Files Using This Class:**
**📁 `src/components/sections/GallerySection.astro`**
  - Line 30: `class="thumbnail-item cursor-pointer group w-full h-full"`
  - Line 20: `<section id="our-work" class="bg-white py-20 md:py-28">`
  - Line 59: `const thumbnails = document.querySelectorAll('.thumbnail-item');`

---

### `.gallery` 🖼️ Gallery

**Usage:** 8 occurrence(s) across 5 file(s)

**CSS Definition:**
```css
--tw-shadow: 0 25px 50px -12px rgb(0 0 0 / 0.25);
  --tw-shadow-colored: 0 25px 50px -12px var(--tw-shadow-color);
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
  outline: 2px solid transparent;
  outline-offset: 2px;
  transform: translateY(-10px) scale(1.03);
  animation-play-state: paused;
}

.gallery .thumbnail-item:nth-child(2) {
  animation-delay: -2s;
  animation-duration: 7s;
}
```

**Files Using This Class:**
**📁 `src/components/QuoteForm.astro`**
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`

**📁 `src/components/Header.astro`**
  - Line 22: `class="`
  - Line 95: `class="`

**📁 `src/components/Footer.astro`**
  - Line 108: `<footer class="bg-slate-950 text-slate-100" role="contentinfo">`

**📁 `src/components/sections/Polaroid.astro`**
  - Line 54: `<div class="gallery-grid">`
  - Line 34: `<section class="polaroid-section">`

**📁 `src/components/sections/GallerySection.astro`**
  - Line 26: `<div class="gallery grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8 justify-items-center items-center">`
  - Line 20: `<section id="our-work" class="bg-white py-20 md:py-28">`

---

### `.suburb-selector` 🗺️ Navigation

**Usage:** 3 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
.suburb-selector {
  position: relative;
  display: inline-block;
}
```

**Files Using This Class:**
**📁 `src/components/Header.astro`**
  - Line 22: `class="`
  - Line 68: `class="bg-transparent appearance-none focus:outline-none cursor-pointer text-slate-900 dark:text-white focus:ring-2 focu...`
  - Line 151: `class="w-full p-2 pr-8 rounded-md bg-slate-100 dark:bg-slate-800 appearance-none text-slate-900 dark:text-white focus:ri...`

---

### `.not-sr-only` 🔧 Utility

**Usage:** 4 occurrence(s) across 2 file(s)

**CSS Definition:**
```css
.not-sr-only {
  position: static;
  width: auto;
  height: auto;
  padding: 0;
  margin: 0;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

**Files Using This Class:**
**📁 `src/layouts/MainLayout.astro`**
  - Line 168: `<a href="#main" class="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:bg-slate-900 focus:text-whit...`
  - Line 101: `<html lang="en" class="scroll-smooth">`

**📁 `src/components/Header.astro`**
  - Line 45: `<span class="sr-only md:not-sr-only font-extrabold text-xl text-slate-900 dark:text-white">`
  - Line 22: `class="`

---

### `.faq-backdrop` ❓ FAQ Section

**Usage:** 2 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
/* CSS rule not found in output.css */
```

**Files Using This Class:**
**📁 `src/components/FAQ.astro`**
  - Line 7: `<section class="faq-backdrop py-16">`
  - Line 7: `<section class="faq-backdrop py-16">`

---

### `.faq-lux` ❓ FAQ Section

**Usage:** 2 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
/* CSS rule not found in output.css */
```

**Files Using This Class:**
**📁 `src/components/FAQ.astro`**
  - Line 9: `<div class="faq-lux">`
  - Line 7: `<section class="faq-backdrop py-16">`

---

### `.faq-polish` ❓ FAQ Section

**Usage:** 3 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
/* CSS rule not found in output.css */
```

**Files Using This Class:**
**📁 `src/components/FAQ.astro`**
  - Line 12: `<details key={i} class="bg-gray-50 p-4 rounded faq-polish">`
  - Line 7: `<section class="faq-backdrop py-16">`
  - Line 40: `document.querySelectorAll('.faq-polish').forEach(d => {`

---

### `.details-marker` 🔧 Utility

**Usage:** 1 occurrence(s) across 1 file(s)

**CSS Definition:**
```css
max-width: 1536px;
  }
}

/* Accordion styles */

.faq-item details[open] summary .details-marker {
  transform: rotate(180deg);
}
```

**Files Using This Class:**
**📁 `src/components/QuoteForm.astro`**
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`

---

### `.selected` 🔧 Utility

**Usage:** 5 occurrence(s) across 3 file(s)

**CSS Definition:**
```css
display: block;
}

.form-checkbox-label.selected {
  --tw-border-opacity: 1;
  border-color: rgb(14 165 233 / var(--tw-border-opacity, 1));
  --tw-bg-opacity: 1;
  background-color: rgb(224 242 254 / var(--tw-bg-opacity, 1));
}
```

**Files Using This Class:**
**📁 `src/components/QuoteForm.astro`**
  - Line 9: `<section id="quote" data-quote class="py-16 md:py-20 bg-gradient-to-b from-sky-50 to-sky-100">`
  - Line 90: `<span class="q-select-icn" aria-hidden="true"><i class="fas fa-chevron-down"></i></span>`

**📁 `src/components/Header.astro`**
  - Line 22: `class="`
  - Line 78: `<svg aria-hidden="true" class="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 dark...`

**📁 `src/components/EnhancedQuoteForm.astro`**
  - Line 19: `<div class="max-w-4xl mx-auto px-6 md:px-8">`

---


## ❌ **UNUSED CUSTOM CLASSES**

*These classes are defined in output.css but not used in the application*

- `.step-number`
- `.error-message`
- `.thumbnail-door`
- `.thumbnail-bath`
- `.thumbnail-sink`
- `.thumbnail-oven`
- `.faq-item`
- `.summary-item`
- `.progress-bar`
- `.progress-fill`
- `.location-badge`
- `.is-visible`

---

## 🚀 **MIGRATION PLAN**

### **Priority 1: Critical Components**


#### Multi-Step Form Classes
- `.step-indicator` → Used in 1 file(s)
- `.step` → Used in 3 file(s)
- `.step-label` → Used in 1 file(s)
- `.form-step` → Used in 1 file(s)
- `.form-checkbox-label` → Used in 1 file(s)

**Impact:** Quote form functionality will break without these classes
**Files affected:** script.js, QuoteForm.astro, [slug].astro



#### Gallery Animation Classes
- `.thumbnail-item` → Used in 1 file(s)
- `.gallery` → Used in 5 file(s)

**Impact:** Gallery hover effects and animations will not work
**Files affected:** GallerySection.astro, QuoteForm.astro, Header.astro, Footer.astro, Polaroid.astro


### **Priority 2: State Management**


#### State Classes
- `.active` → Used in 3 file(s)
- `.completed` → Used in 1 file(s)
- `.invalid` → Used in 2 file(s)
- `.selected` → Used in 3 file(s)

**Impact:** Interactive states and form validation styling


### **Priority 3: Layout & Navigation**


#### Navigation & FAQ Classes
- `.suburb-selector` → Used in 1 file(s)
- `.not-sr-only` → Used in 2 file(s)
- `.faq-backdrop` → Used in 1 file(s)
- `.faq-lux` → Used in 1 file(s)
- `.faq-polish` → Used in 1 file(s)

**Impact:** Header navigation and FAQ section styling


---

## 🧪 **TESTING REQUIREMENTS**

After migrating these classes, test:

- [ ] **Multi-step quote form**: Navigation, validation, step indicators
- [ ] **Gallery interactions**: Hover effects, animations, clip-path thumbnails
- [ ] **Header navigation**: Suburb selector dropdown, accessibility
- [ ] **FAQ sections**: Accordion behavior, styling
- [ ] **Interactive states**: Form validation, active states, selections

---

## 📋 **NEXT STEPS**

1. **Copy CSS rules** from the definitions above into `src/styles/main.css`
2. **Remove output.css references** using `npm run audit:output-css -- --fix`
3. **Delete output.css file** and add to .gitignore
4. **Test all functionality** using the checklist above
5. **Deploy** and verify everything works in production

**Estimated time:** 30-45 minutes
**Risk level:** Low (all essential classes identified)

---

*Generated by: `npm run generate:focused-summary`*