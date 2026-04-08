import type { NextConfig } from 'next'
import * as dotenv from 'dotenv'
import * as path from 'path'

dotenv.config({ path: path.resolve(process.cwd(), '../.env.local') })

const isDev = process.env.NODE_ENV === 'development'
const lambdaUrl = process.env.LAMBDA_API_URL ?? ''

const nextConfig: NextConfig = {
  allowedDevOrigins: process.env.NEXT_DEV_ORIGINS?.split(',') ?? [],
  ...(isDev ? {} : { output: 'export' }),
  images: { unoptimized: true },
  trailingSlash: true,
  env: {
    NEXT_PUBLIC_API_URL: isDev ? '/api' : lambdaUrl,
    NEXT_PUBLIC_S3_BASE: process.env.NEXT_PUBLIC_S3_BASE ?? '',
  },
  async rewrites() {
    if (!isDev) return []
    return [
      {
        source: '/api/:path*',
        destination: `${lambdaUrl}/:path*`,
      },
    ]
  },
}

export default nextConfig
