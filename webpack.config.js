'use strict';
const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: './src/frontend/api.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, 'dist'),
  },

  optimization: {
    minimize: false
  }
};