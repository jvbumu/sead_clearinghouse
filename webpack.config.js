
const path = require('path')
const webpack = require('webpack')
const HtmlPlugin = require("html-webpack-plugin");

module.exports = {
  entry: path.join(__dirname, 'public/js/main.js'),
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist')
  },
  module: {
    rules: [{
      test: /.jsx?$/,
      include: [
        path.resolve(__dirname, 'public')
      ],
      exclude: [
        path.resolve(__dirname, 'node_modules'),
        path.resolve(__dirname, 'public/api'),
        //path.resolve(__dirname, 'public/lib'),
      ],
      loader: 'babel-loader',
      query: {
        presets: ['es2015']
      }
    }]
  },
  plugins: [
    new HtmlPlugin({
        template: "./public/index.html",
        inject: "body"
    })
  ],
  resolve: {
    extensions: ['.json', '.js', '.jsx', '.css']
  },
  devtool: 'source-map',
  devServer: {
    publicPath: path.join('/dist/')
  }
};