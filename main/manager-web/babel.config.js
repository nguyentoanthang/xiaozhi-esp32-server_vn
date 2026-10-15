module.exports = {
  presets: [
    ['@vue/cli-plugin-babel/preset', {
      useBuiltIns: 'usage',
      corejs: 3
    }]
  ],
  plugins: [
    '@babel/plugin-syntax-dynamic-import',  // Ensure dynamic import support (Lazy Loading)
    '@babel/plugin-transform-runtime'
  ]
}
