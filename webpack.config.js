
const path = require('path');
const webpack = require('webpack');
const HtmlPlugin = require("html-webpack-plugin");

// Will be used to copy API dir: https://webpack.js.org/plugins/copy-webpack-plugin/
// const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
    mode: 'development',
    entry: path.join(__dirname, 'public/js/main.js'),
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'public')
    },
    module: {
        rules: [
            {
                enforce: "pre",
                test: /\.js$/,
                exclude: /node_modules/,
                loader: "eslint-loader",
            },
            {
                test: /\.js$/,
                include: [ path.join(__dirname, 'public') ],
                exclude: /(node_modules|bower_components)/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            },
            // {
            //     test : /\.(png|gif|jpg|jpeg)$/,
            //     loader: "file-loader"
            // },
            {
                test: /\.(png|gif|jp(e*)g|svg)$/,
                use: [{
                    loader: 'url-loader',
                    options: { limit: 100000, name: 'images/[hash]-[name].[ext]' }
                }]
            },
            {
                test: /\.html$/,
                use: [{
                    loader: 'html-loader',
                    options: {
                        ignoreCustomFragments: [/\{\{.*?}}/],
                        root: path.resolve(__dirname, 'images'),
                        attrs: ['img:src' ]
                    }
                }]
            }
        ]
    },
    plugins: [
        new webpack.LoaderOptionsPlugin({ options: {} }),
        new HtmlPlugin({
            template: "./public/index-template.html",
            inject: "body"
        }),
        new webpack.ProvidePlugin({
            $: "jquery",
            jQuery: "jquery",
            'window.jQuery': 'jquery',
            'window.$': 'jquery',
            _: "underscore",
            Backbone : "backbone",
        })
    ],
    resolve: {
        extensions: [ '.json', '.js', '.jsx', '.css' ],
        modules: [
            path.resolve('./node_modules'),
        ],
        alias: {
            ImageFiles: path.resolve(__dirname, 'public/images/'),
            CssFiles: path.resolve(__dirname, 'public/css/'),
            TemplateFiles: path.resolve(__dirname, 'public/templates/')
        }
    },
    devtool: 'source-map',
    devServer: {
        publicPath: path.join('/dist/')
    }
};