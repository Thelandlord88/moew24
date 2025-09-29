# Hunt Fix-It Brief (2025-09-18T12:17:40.247Z)

## `.mjs` uses `require()`

**Recipe**:
```js
// before
const x = require('pkg');
// after
import x from 'pkg';
```

