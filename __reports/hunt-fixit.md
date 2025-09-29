# Hunt Fix-It Brief (2025-09-24T07:51:09.426Z)

## `.mjs` uses `require()`

**Recipe**:
```js
// before
const x = require('pkg');
// after
import x from 'pkg';
```

