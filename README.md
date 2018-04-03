
Webpackify project:

npm remove webpack webpack-cli -g

npm init -y
npm install webpack@next webpack-cli --save-dev
npm install html-webpack-plugin --save-dev
npm install eslint eslint-loader --save-dev
npm install backbone --save
npm install jquery --save
npm install underscore --save
npm install datatables --save
npm install spin --save
npm install bootstrap popper.js --save
npm install datatables.net datatables.net-bs4 --save// https://www.datatables.net/download/npm
npm install datatables.net-buttons datatables.net-buttons-bs4 --save
npm install datatables.net-select datatables.net-select-bs4 --save
npm install datatables.net-responsive datatables.net-responsive-bs4 --save

npm install "babel-loader@^8.0.0-beta" @babel/core @babel/preset-env webpack --save-dev
npm i file-loader css-loader style-loader --save-dev
npx webpack --config webpack.config.js