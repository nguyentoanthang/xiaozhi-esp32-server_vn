// # Running `pnpm upgrade` upgrades the `uniapp` related dependencies
// # After the upgrade, many useless dependencies are added automatically; remove them to reduce the package size
// # Just run the commands below

const { exec } = require('node:child_process')

// Define the commands to run
const dependencies = [
  '@dcloudio/uni-app-harmony',
  // TODO: if you do not need the mini program for a platform, delete or comment it out manually
  '@dcloudio/uni-mp-alipay',
  '@dcloudio/uni-mp-baidu',
  '@dcloudio/uni-mp-jd',
  '@dcloudio/uni-mp-kuaishou',
  '@dcloudio/uni-mp-lark',
  '@dcloudio/uni-mp-qq',
  '@dcloudio/uni-mp-toutiao',
  '@dcloudio/uni-mp-xhs',
  '@dcloudio/uni-quickapp-webview',
  // For the i18n template, comment out the following
  'vue-i18n',
]

// Run the commands with exec
exec(`pnpm un ${dependencies.join(' ')}`, (error, stdout, stderr) => {
  if (error) {
    // If there is an error, print the error message
    console.error(`Execution error: ${error}`)
    return
  }
  // Print normal output
  console.log(`stdout: ${stdout}`)
  // If there is error output, print it too
  console.error(`stderr: ${stderr}`)
})
