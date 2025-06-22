const path = require('path');

module.exports = {
  entry: './renderer/index.tsx',
  target: 'electron-renderer',
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: {
          loader: 'ts-loader',
          options: {
            configFile: path.resolve(__dirname, 'renderer/tsconfig.json')
          }
        },
        exclude: /node_modules/,
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader', 'postcss-loader'],
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.css'],
    alias: {
      '@': path.resolve(__dirname, 'renderer'),
    },
  },
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, 'renderer/dist'),
  },
};