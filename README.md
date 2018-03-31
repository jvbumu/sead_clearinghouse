
Webpackify project:

npm remove webpack webpack-cli -g

npm init -y
npm install webpack@next webpack-cli --save-dev
npm install html-webpack-plugin --save-dev

npm install backbone --save
npm install jquery --save
npm install underscore --save
npm install datatables --save
npm install spin --save
npm install bootstrap popper.js --save

npm install "babel-loader@^8.0.0-beta" @babel/core @babel/preset-env webpack --save-dev
npm i file-loader css-loader --save-dev
npx webpack --config webpack.config.js