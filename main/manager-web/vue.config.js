const { defineConfig } = require('@vue/cli-service');
const dotenv = require('dotenv');
// TerserPlugin is used to minify JavaScript
const TerserPlugin = require('terser-webpack-plugin');
// CompressionPlugin enables Gzip compression
const CompressionPlugin = require('compression-webpack-plugin')
// BundleAnalyzerPlugin is used to analyze the bundled files
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
// WorkboxPlugin is used to generate the Service Worker
const { InjectManifest } = require('workbox-webpack-plugin');
// Import the path module

const path = require('path')

function resolve(dir) {
  return path.join(__dirname, dir)
}

// Make sure the .env file is loaded
dotenv.config();

// Define the CDN resource list so the Service Worker can also access it
const cdnResources = {
  css: [
    'https://unpkg.com/element-ui@2.15.14/lib/theme-chalk/index.css',
    'https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css'
  ],
  js: [
    'https://unpkg.com/vue@2.6.14/dist/vue.min.js',
    'https://unpkg.com/vue-router@3.6.5/dist/vue-router.min.js',
    'https://unpkg.com/vuex@3.6.2/dist/vuex.min.js',
    'https://unpkg.com/element-ui@2.15.14/lib/index.js',
    'https://unpkg.com/axios@0.27.2/dist/axios.min.js',
    'https://unpkg.com/opus-decoder@0.7.7/dist/opus-decoder.min.js'
  ]
};

// Determine whether to use CDN
const useCDN = process.env.VUE_APP_USE_CDN === 'true';

module.exports = defineConfig({
  productionSourceMap: process.env.NODE_ENV !== 'production', // do not generate source maps in production
  devServer: {
    port: 8001, // specify port 8001
    proxy: {
      '/xiaozhi': {
        target: 'http://127.0.0.1:8002',
        changeOrigin: true
      }
    },
    client: {
      overlay: false, // do not show the webpack error overlay
    },
  },
  publicPath: process.env.VUE_APP_PUBLIC_PATH || "/",
  chainWebpack: config => {

    // Modify the HTML plugin configuration to insert CDN links dynamically
    config.plugin('html')
      .tap(args => {
        // Decide whether to use CDN based on the configuration
        if (process.env.NODE_ENV === 'production' && useCDN) {
          args[0].cdn = cdnResources;
        }
        return args;
      });

    // Code splitting optimization
    config.optimization.splitChunks({
      chunks: 'all',
      minSize: 20000,
      maxSize: 250000,
      cacheGroups: {
        vendors: {
          name: 'chunk-vendors',
          test: /[\\/]node_modules[\\/]/,
          priority: -10,
          chunks: 'initial',
        },
        common: {
          name: 'chunk-common',
          minChunks: 2,
          priority: -20,
          chunks: 'initial',
          reuseExistingChunk: true,
        },
      }
    });

    // Enable optimization settings
    config.optimization.usedExports(true);
    config.optimization.concatenateModules(true);
    config.optimization.minimize(true);
  },
  configureWebpack: config => {
    if (process.env.NODE_ENV === 'production') {
      // Enable multi-threaded compilation
      config.optimization = {
        minimize: true,
        minimizer: [
          new TerserPlugin({
            parallel: true,
            terserOptions: {
              compress: {
                drop_console: true,
                drop_debugger: true,
                pure_funcs: ['console.log']
              }
            }
          })
        ]
      };
      config.plugins.push(
        new CompressionPlugin({
          algorithm: 'gzip',
          test: /\.(js|css|html|svg)$/,
          threshold: 20480,
          minRatio: 0.8
        })
      );

      // Decide whether to add the Service Worker based on whether CDN is used
      config.plugins.push(
        new InjectManifest({
          swSrc: path.resolve(__dirname, 'src/service-worker.js'),
          swDest: 'service-worker.js',
          exclude: [/\.map$/, /asset-manifest\.json$/],
          maximumFileSizeToCacheInBytes: 5 * 1024 * 1024, // 5MB
          // Custom Service Worker injection point
          injectionPoint: 'self.__WB_MANIFEST',
          // Pass extra information to the Service Worker
          additionalManifestEntries: useCDN ?
            [{ url: 'cdn-mode', revision: 'enabled' }] :
            [{ url: 'cdn-mode', revision: 'disabled' }]
        })
      );

      // If CDN is used, configure externals to exclude dependency packages
      if (useCDN) {
        config.externals = {
          'vue': 'Vue',
          'vue-router': 'VueRouter',
          'vuex': 'Vuex',
          'element-ui': 'ELEMENT',
          'axios': 'axios',
          'opus-decoder': 'OpusDecoder'
        };
      } else {
        // Make sure externals is not set when CDN is not used, so webpack bundles all dependencies
        config.externals = {};
      }

      if (process.env.ANALYZE === 'true') {  // controlled via environment variable
        config.plugins.push(
          new BundleAnalyzerPlugin({
            analyzerMode: 'server',    // enable local server mode
            openAnalyzer: true,        // open the browser automatically
            analyzerPort: 8888         // specify the port number
          })
        );
      }
      config.cache = {
        type: 'filesystem',  // use filesystem cache
        cacheDirectory: path.resolve(__dirname, '.webpack_cache'),  // custom cache directory
        allowCollectingMemory: true,  // enable memory collection
        compression: 'gzip',  // enable gzip cache compression
        maxAge: 5184000000, // cache validity of 1 month
        buildDependencies: {
          config: [__filename]  // invalidate the cache whenever the config file changes
        }
      };
    }
  },
  // Expose CDN resource info to service-worker.js
  pwa: {
    workboxOptions: {
      skipWaiting: true,
      clientsClaim: true
    }
  }
});
