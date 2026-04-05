import nextConfig from 'eslint-config-next'

const config = [
  {
    ignores: ['.next/', 'node_modules/', 'out/', 'public/'],
  },
  ...nextConfig,
]

export default config
