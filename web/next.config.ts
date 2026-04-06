import type { NextConfig } from 'next'
import * as dotenv from 'dotenv'
import * as path from 'path'

dotenv.config({ path: path.resolve(process.cwd(), '../.env.local') })

const nextConfig: NextConfig = {
  output: 'export',
  images: { unoptimized: true },
  trailingSlash: true,
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? '',
    NEXT_PUBLIC_S3_BASE: process.env.NEXT_PUBLIC_S3_BASE ?? '',
  },
}

export default nextConfig
