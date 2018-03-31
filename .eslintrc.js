module.exports = {
  //"root": true,
  "parser": 'babel-eslint',
  "parserOptions": {
    "ecmaVersion": 6,
    "sourceType": 'module' // script
  },
  "env": {
    "browser": true,
    "mocha": true
  },
  "extends": 'eslint:recommended',
  "rules": {
    "indent": ["error", 4],
    "no-console": ["error", { allow: ["log", "warn", "error"] }],
    //"quotes": [2, "single"],
    // allow debugger during development
    //"no-debugger": process.env.NODE_ENV === 'production' ? 2 : 0
    "arrow-parens": 0
  },
  "globals": {
    "document": true,
    "window": true,
    "console": true,
    "__dirname": true,
    "require": true,
    "process": true,
    "module": true,
    "Map": true,
    "Promise": true
  }
}
