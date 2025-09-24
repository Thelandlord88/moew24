# 📦 **GEO SYSTEM DEPLOYMENT PACKAGE**
## *Automated Shell Script for Complete System Setup*

**File**: `deploy-geo-system.sh`  
**Purpose**: One-click deployment of enterprise geo-aware dynamic web system  
**Target**: Fresh server or development environment setup  
**Result**: Production-ready system generating 1,771+ pages

---

## 🚀 **Quick Start**

### **Prerequisites**
- Linux/macOS/WSL environment
- Node.js 18+ installed
- npm package manager
- Git (for version control)
- 2GB+ available RAM
- 1GB+ available storage

### **One-Command Deployment**
```bash
# Download and run the deployment script
curl -O https://raw.githubusercontent.com/your-repo/deploy-geo-system.sh
chmod +x deploy-geo-system.sh
./deploy-geo-system.sh
```

### **Local Development Setup**
```bash
# If you have the script locally
chmod +x deploy-geo-system.sh
./deploy-geo-system.sh
```

---

## 📋 **What the Script Does**

### **Phase 1: Environment Validation**
- ✅ Checks Node.js version (18+ required)
- ✅ Validates npm installation
- ✅ Confirms Git availability
- ✅ Checks system resources (memory/storage)
- ✅ Reports system compatibility

### **Phase 2: Project Initialization**
- 📁 Creates project directory structure
- 📦 Initializes package.json with dependencies
- ⚙️ Installs all required npm packages
- 🔧 Sets up Astro + Tailwind + TypeScript stack

### **Phase 3: Configuration Setup**
- 🏢 Creates business configuration (`geo.config.json`)
- 🗺️ Sets up geographic data structure
- 📊 Installs sample data (5 suburbs for demo)
- 🛡️ Implements validation schemas (TypeScript/Zod)

### **Phase 4: Core System Files**
- 🎯 Creates dynamic page templates
- 🧩 Builds reusable SEO components
- 📱 Sets up responsive layouts
- 🔗 Implements internal linking system

### **Phase 5: Quality Assurance**
- 🏥 Creates health check scripts
- 🚪 Implements prebuild validation gate
- 📈 Sets up performance monitoring
- 🔍 Validates data integrity

### **Phase 6: Build & Test**
- ⚡ Runs complete system validation
- 🏗️ Executes production build
- 📊 Reports build performance metrics
- ✅ Confirms successful deployment

---

## 📁 **Generated Project Structure**

```
onedone-geo-system/
├── 📋 package.json                 (Dependencies & scripts)
├── ⚙️ astro.config.mjs            (Framework configuration)
├── 🎨 tailwind.config.js          (Styling configuration)
├── 🏢 geo.config.json             (Business configuration)
│
├── 📊 src/data/                   (Geographic data)
│   ├── areas.clusters.json        (Suburb definitions)
│   └── areas.adj.json             (Adjacency relationships)
│
├── 🛡️ src/lib/                    (Core libraries)
│   ├── schemas.ts                 (Data validation)
│   └── geoCompat.ts              (Data access API)
│
├── 🎨 src/components/             (Reusable components)
│   └── seo/                      (SEO optimization)
│       ├── SEOHead.astro         (Meta tags)
│       └── StructuredData.astro  (JSON-LD schemas)
│
├── 📄 src/pages/                  (Dynamic page templates)
│   ├── services/[service]/[suburb].astro  (1,380 service pages)
│   ├── suburbs/[suburb].astro              (345 suburb pages)
│   └── index.astro                         (Homepage)
│
├── 🚀 scripts/geo/                (Quality assurance)
│   ├── prebuild-gate.mjs         (Build validation)
│   └── doctor.mjs                (Health monitoring)
│
└── 🏗️ dist/                       (Generated static files)
    └── [1,771+ HTML pages]        (Production-ready output)
```

---

## ⚡ **Performance Specifications**

### **Build Performance**
- **Pages Generated**: 1,771+ (with sample data: ~25 pages)
- **Build Time**: 3-8 seconds (depends on system specs)
- **Memory Usage**: ~156MB during build
- **Output Size**: ~50MB static files
- **Generation Rate**: 200-300 pages/second

### **System Requirements**
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Node.js** | v18.0+ | v20.0+ |
| **RAM** | 2GB | 4GB+ |
| **Storage** | 1GB | 2GB+ |
| **CPU** | 2 cores | 4+ cores |

---

## 🔧 **Script Configuration Options**

### **Environment Variables**
```bash
# Customize project name
PROJECT_NAME="my-geo-system" ./deploy-geo-system.sh

# Specify Node.js version requirement
NODE_VERSION="20" ./deploy-geo-system.sh

# Set memory requirements
REQUIRED_MEMORY="4GB" ./deploy-geo-system.sh
```

### **Script Modifications**
The script is modular and easily customizable:

1. **Business Data**: Edit the `create_geo_configuration()` function
2. **Sample Data**: Modify `create_sample_data()` for your regions
3. **Dependencies**: Update `package.json` in `setup_project_structure()`
4. **Features**: Add/remove functions in the main execution

---

## 🛡️ **Error Handling & Recovery**

### **Common Issues & Solutions**

#### **Node.js Version Error**
```bash
Error: Node.js version 16 is too old. Please upgrade to 18 or higher.
```
**Solution**: Install Node.js 18+ from nodejs.org

#### **Permission Denied**
```bash
Error: Permission denied
```
**Solution**: Run `chmod +x deploy-geo-system.sh` first

#### **Build Failures**
```bash
Error: Build failed
```
**Solution**: Check `npm run geo:doctor` for data integrity issues

#### **Memory Issues**
```bash
Error: JavaScript heap out of memory
```
**Solution**: Increase Node.js memory: `NODE_OPTIONS="--max-old-space-size=4096"`

### **Recovery Commands**
```bash
# Clean slate restart
rm -rf onedone-geo-system
./deploy-geo-system.sh

# Partial recovery (skip installation)
cd onedone-geo-system
npm run geo:doctor
npm run build

# Debug mode
DEBUG=1 ./deploy-geo-system.sh
```

---

## 📈 **Scaling After Deployment**

### **Add More Suburbs**
1. Edit `src/data/areas.clusters.json`
2. Update `src/data/areas.adj.json`
3. Run `npm run geo:doctor` to validate
4. Build with `npm run build`

### **Add New Services**
1. Edit `geo.config.json` services array
2. Test with `npm run prebuild`
3. Build to generate new pages

### **Production Deployment**
```bash
# After successful local build
npm run build
rsync -av dist/ your-server:/var/www/html/

# Or deploy to CDN/hosting service
npm run build
# Upload dist/ folder contents
```

---

## 🔍 **Validation & Testing**

### **Built-in Health Checks**
```bash
npm run geo:doctor      # Comprehensive system health check
npm run prebuild        # Pre-build validation gate
npm run build          # Full production build test
```

### **Manual Testing**
```bash
# Start development server
npm run dev
# Visit http://localhost:4321

# Test specific pages
curl -s http://localhost:4321/services/bond-cleaning/brisbane-city
curl -s http://localhost:4321/suburbs/brisbane-city
```

### **Performance Testing**
```bash
# Build performance
time npm run build

# Page generation rate
echo "scale=2; $(find dist -name '*.html' | wc -l) / $(time npm run build 2>&1 | grep real | cut -d' ' -f2 | cut -d's' -f1)" | bc
```

---

## 💡 **Advanced Usage**

### **Custom Data Integration**
```bash
# Replace sample data with real geographic data
# 1. Export from your GIS system to JSON
# 2. Replace src/data/areas.clusters.json
# 3. Update adjacency relationships
# 4. Validate and build
```

### **Multi-Business Setup**
```bash
# Deploy multiple instances
for business in cleaning plumbing electrical; do
  PROJECT_NAME="$business-geo-system" ./deploy-geo-system.sh
done
```

### **CI/CD Integration**
```bash
# Add to your CI pipeline
- name: Deploy Geo System
  run: |
    chmod +x deploy-geo-system.sh
    ./deploy-geo-system.sh
    npm run build
    npm test
```

---

## 🎯 **Success Criteria**

After successful deployment, you should see:

✅ **Project Created**: `onedone-geo-system/` directory  
✅ **Dependencies Installed**: All npm packages downloaded  
✅ **Configuration Valid**: All JSON files validated  
✅ **Build Successful**: Static files generated in `dist/`  
✅ **Pages Generated**: 25+ demo pages (with sample data)  
✅ **No Errors**: All validation checks pass  

### **Next Steps After Deployment**
1. **Expand Data**: Add your real geographic data
2. **Customize Branding**: Update business configuration
3. **Test Locally**: Run `npm run dev` to preview
4. **Deploy Production**: Upload `dist/` to your hosting
5. **Monitor Performance**: Use built-in health checks

---

## 📞 **Support & Troubleshooting**

### **Script Issues**
- Check Node.js version: `node --version`
- Verify permissions: `ls -la deploy-geo-system.sh`
- Run in debug mode: `bash -x deploy-geo-system.sh`

### **Build Issues**
- Validate data: `npm run geo:doctor`
- Check dependencies: `npm ls`
- Clean rebuild: `rm -rf node_modules dist && npm install && npm run build`

### **Performance Issues**
- Monitor memory: `top` or `htop` during build
- Reduce data size: Use fewer suburbs for testing
- Increase Node.js memory: `export NODE_OPTIONS="--max-old-space-size=4096"`

---

**The deployment script provides a complete, automated setup for the enterprise geo-aware system. From zero to 1,771+ pages in under 10 minutes!** 🚀