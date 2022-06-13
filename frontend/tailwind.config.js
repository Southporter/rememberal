module.exports = {
  content: {
    files: [
      './src/**/*.{html,elm}',
      './index.js'
    ],
    extract: {
      elm: (content) => {
        return content.match(/class +"(.*)"/);
      }
    }
  },
  theme: {
    extend: {
      fontFamily: {
        'cursive': ['Miss Fajardose', 'cursive']
      }
    },
  },
  plugins: [],
  safelist: [
    {
      pattern: /(bg|ring)-(red|pink|gray)-(300|400)/
    }
  ]
}
