import nextConfig from 'eslint-config-next'

const config = [
  {
    ignores: ['.next/', 'node_modules/', 'out/', 'public/'],
  },
  ...nextConfig,
  {
    rules: {
      '@next/next/no-img-element': 'off',
    },
  },
]

export default config
