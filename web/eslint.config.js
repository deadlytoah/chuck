export default [
  {
    ignores: ['.next/', 'node_modules/', 'out/', 'public/'],
  },
  {
    rules: {
      'react/react-in-jsx-scope': 'off',
      '@next/next/no-html-link-for-pages': 'off',
    },
  },
]
